//
//  Basket.swift
//  Acheron
//
//  Created by Joe Charlier on 4/23/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

#if !os(Linux)

import Foundation

public class Basket: NSObject {
    let persist: Persist

    var blocks: [String:[(Domain)->()]] = [:]
    
    public var fork: Int

    var cache: SafeMap = SafeMap<Anchor>()
    var onlyToIden: SafeMap = SafeMap<String>()
    var dirty = SafeSet<Anchor>()
    var dehydrate = SafeSet<Domain>()

    let queue: DispatchQueue
    
    let generateIden:(Domain.Type)->(String) = {(type: Domain.Type) -> (String) in UUID().uuidString }
    
    public init(_ persist: Persist) {
        self.persist = persist
        queue = DispatchQueue(label: self.persist.name)
        fork = Int(persist.get(key: "fork") ?? "0")!
    }
    
    public func associate(type: String, only: String) { persist.associate(type: type, only: only) }
    public func only(type: String) -> String? { persist.only(type: type) }
        
    private func load(_ attributes: [String:Any], cls: Anchor.Type) -> Anchor {
        let anchor = cls.init(attributes: attributes)
        anchor.basket = self
        anchor.load(attributes: attributes)
        cache[anchor.iden] = anchor
        if let onlyKey = persist.typeToOnly[anchor.type], let type = anchor.type, let only = attributes[onlyKey] {
            onlyToIden["\(type):\(only)"] = anchor.iden
        }
        return anchor
    }
    private func load(_ attributes: [String:Any]) -> Anchor {
        let cls = Loom.classFromName(attributes["type"] as! String) as! Anchor.Type
        return load(attributes, cls: cls)
    }
    public func inject(_ attributes: [String:Any]) -> Anchor {
        let anchor = load(attributes)
        anchor.dirty()
        return anchor
    }
    
    public func createBy(cls: Anchor.Type, only: String? = nil) -> Anchor {
        let anchor = cls.init(basket: self)
        anchor.iden = generateIden(cls)
        cache[anchor.iden] = anchor
        if let only = only {
            onlyToIden["\(anchor.type!):\(only)"] = anchor.iden
        }
        dirty.insert(anchor)
        return anchor
    }
    
    private func convert(array: [[String:Any]]) -> [Anchor] {
        var anchors: [Anchor] = []
        for attributes in array {
            var anchor = cache[attributes["iden"] as! String]
            if anchor == nil {
                anchor = load(attributes)
            }
            anchors.append(anchor!)
        }
        return anchors;
    }
    private func convert(array: [[String:Any]], type:Anchor.Type) -> [Anchor] {
        var anchors: [Anchor] = []
        for attributes in array {
            var anchor = cache[attributes["iden"] as! String]
            if anchor == nil {
                anchor = load(attributes, cls: type)
            }
            anchors.append(anchor!)
        }
        return anchors;
    }
    
    public func selectBy(iden: String) -> Anchor? {
        var result: Anchor? = nil
        if let anchor = cache[iden] {
            result = anchor
        } else if let attributes = persist.attributes(iden: iden) {
            result = load(attributes)
        }
        return result
    }
    public func selectBy(cls: Anchor.Type, only: String) -> Anchor? {
        var result: Anchor? = nil
        let type = String(describing: cls).lowercased()
        if let iden = onlyToIden["\(type):\(only)"], let anchor = cache[iden] {
            result = anchor
        } else if let attributes = persist.attributes(type: type, only: only) {
            result = load(attributes)
        }
        return result
    }
    public func selectOne(where field: String, is value: String, type: Anchor.Type) -> Domain? {
        guard let attributes = persist.selectOne(where: field, is: value, type: Loom.nameFromType(type)) else { return nil }
        return cache[attributes["iden"] as! String] ?? load(attributes, cls: type)
    }
    public func select(where field: String, is value: String, type: Anchor.Type) -> [Domain] {
        let array = persist.select(where: field, is: value, type: Loom.nameFromType(type))
        return convert(array: array, type:type)
    }
    public func selectAll(_ type: Anchor.Type) -> [Anchor] {
        let array = persist.selectAll(type: Loom.nameFromType(type))
        return convert(array: array, type: type)
    }
    public func selectForked() -> [Anchor] {
        let array = persist.selectForked()
        return convert(array: array)
    }
    public func selectForkedMemories() -> [[String:Any]] { persist.selectForkedMemories() }
    
    public func syncPacket() -> [String:Any] {
        var attributes: [String:Any] = [:]
        
        queue.sync {
            var documents: [[String:Any]] = []
            for anchor in selectForked() {
                if anchor.isUploaded {
                    documents.append(anchor.unload())
                }
            }
            
            attributes["fork"] = persist.get(key: "fork")
            attributes["documents"] = documents
            attributes["deleted"] = []
            attributes["memories"] = selectForkedMemories()
        }
        
        return attributes
    }
    
    func dirtyAnchor(_ anchor: Anchor) { dirty.insert(anchor) }
    func deleteAnchor(_ anchor: Anchor) {
        dirty.insert(anchor)
        cache.removeValue(forKey: anchor.iden)
    }
    
    func deleteByID(_ iden: String ) {}
    
    private func key(class cls: Domain.Type, action: DomainAction) -> String {
        return "\(String(describing: cls))_\(action)"
    }
    func addBlock(class cls: Domain.Type, action: DomainAction, block: @escaping (Domain)->()) {
        let key = self.key(class: cls, action: action)
        if blocks[key] == nil {
            blocks[key] = []
        }
        blocks[key]!.append(block)
    }
    public func addBlock(_ block: @escaping (Domain)->(), class cls: Domain.Type, event: DomainAction) {
        addBlock(class: cls, action: event, block: block)
    }
    func blocksFor(class cls: Domain.Type, action: DomainAction) -> [(Domain)->()] {
        let key = self.key(class: cls, action: action)
        return blocks[key] ?? []
    }
    
    private static func loadDirty(into: inout Set<Domain>, domain: Domain) {
        into.insert(domain)
        for child in domain.allDomainChildren {
            if child.status != .clean {
                loadDirty(into:&into, domain:child)
            }
        }
    }
    
    public func transact(_ closure: ()->()) {
        var dirty = Set<Anchor>()
        
        var editedAnchors = Set<Anchor>()
        var deletedAnchors = Set<Anchor>()
        var editedDomains = Set<Domain>()
        var deletedDomains = Set<Domain>()

        queue.sync {
            autoreleasepool {
                closure()
                
                while self.dirty.count > 0 {
                    dirty.formUnion(self.dirty)
                    
                    var dirtyDomains = Set<Domain>()
                    for anchor in self.dirty {
                        dirtyDomains.formUnion(anchor.deepSearchChildren({ (domain: Domain) -> (Bool) in
                            return domain.status != .clean
                        }))
                    }
                    self.dirty.removeAll()
                    dirtyDomains.forEach { $0.dirtied() }
                }
                
                deletedDomains.formUnion(self.dehydrate)
                
                for anchor in dirty {
                    if anchor.status == .deleted {
                        deletedAnchors.insert(anchor)
                        deletedDomains.insert(anchor)
                    } else {
                        editedAnchors.insert(anchor)
                        Basket.loadDirty(into:&editedDomains, domain:anchor)
                        anchor.save()
                    }
                }
            }
        }

        if dirty.count > 0 {
            self.persist.transact({ () -> (Bool) in
                autoreleasepool {
                    for anchor in deletedAnchors {
                        if let only = anchor.only { onlyToIden["\(anchor.type!):\(only)"] = nil }
                        persist.delete(iden: anchor.iden)
                    }
                    for anchor in editedAnchors {
                        if let only = anchor.only { onlyToIden["\(anchor.type!):\(only)"] = anchor.iden }
                        persist.store(iden: anchor.iden, attributes: anchor.unload())
                    }
                }
                return true
            })
        }
    }
    
    public func clearCache() {
        queue.sync { cache.removeAll() }
    }
    
    public func set(key: String, value: String) { persist.set(key: key, value: value) }
    public func setServer(key: String, value: String) { persist.setServer(key: key, value: value) }
    public func get(key: String) -> String? { persist.get(key: key) }
    public func unset(key: String) { persist.unset(key: key) }
    
    public func show() { persist.show() }
    func showID(_ iden: String) { persist.show(iden) }
    
    public func wipe() {
        queue.sync {
            persist.wipe()
            fork = 0
            cache.removeAll()
            dirty.removeAll()
            dehydrate.removeAll()
        }
    }
    public func wipeDocuments() {
        queue.sync {
            persist.wipeDocuments()
            fork = 0
            cache.removeAll()
            dirty.removeAll()
            dehydrate.removeAll()
        }
    }

    public func printDocuments() { persist.show() }
    public func printCensus() { persist.census() }
}

#endif
