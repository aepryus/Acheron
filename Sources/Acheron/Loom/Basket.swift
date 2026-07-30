//
//  Basket.swift
//  Acheron
//
//  Created by Joe Charlier on 4/23/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

#if !os(Linux)

import Foundation

/// How strictly this basket's anchors must honor the transact boundary. A mutation of a
/// persisted Anchor outside a transact is a bug — `.warning` (the default) logs each one;
/// `.strict` reprises the 2003 Java rule and fails fast; `.tolerant` silences the check.
/// The basket-wide sweep still commits strays either way: staleness, not loss.
public enum BasketDiscipline { case tolerant, warning, strict }

public class Basket {
    let persist: Persist

    var blocks: [String:[(Domain)->()]] = [:]

    public var fork: Int

    public var discipline: BasketDiscipline = .warning
    private let inTransactKey = DispatchSpecificKey<Bool>()

    var cache: SafeMap = SafeMap<Anchor>()
    var onlyToIden: SafeMap = SafeMap<String>()
    var dirty = SafeSet<Anchor>()
    var dehydrate = SafeSet<Domain>()
    private var pendingStores: [String:[String:Any]] = [:]
    private var pendingDeletes: Set<String> = []

    let queue: DispatchQueue
    let commitQueue: DispatchQueue
    
    let generateIden:(Domain.Type)->(String) = {(type: Domain.Type) -> (String) in UUID().uuidString }
    
    public init(_ persist: Persist) {
        self.persist = persist
        queue = DispatchQueue(label: self.persist.name)
        commitQueue = DispatchQueue(label: self.persist.name + ".commit")
        queue.setSpecific(key: inTransactKey, value: true)
        fork = Int(persist.get(key: "fork") ?? "0")!
    }
    
    public func associate(type: String, only: String) { persist.associate(type: type, only: only) }
    public func index(type: String, field: String) { persist.index(type: type, field: field) }
    public func only(type: String) -> String? { persist.only(type: type) }

    private var onQueue: Bool { DispatchQueue.getSpecific(key: inTransactKey) == true }
    private func sync<T>(_ block: () -> T) -> T { onQueue ? block() : queue.sync(execute: block) }
        
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
        guard let type = attributes["type"] as? String else { fatalError("Loom: document \(attributes["iden"] ?? "?") has no type field; the row is malformed") }
        guard let cls = Loom.classForType(type) as? Anchor.Type else { fatalError("Loom: type '\(type)' is not an Anchor; a non-anchor document reached the basket") }
        return load(attributes, cls: cls)
    }
    public func inject(_ attributes: [String:Any]) -> Anchor {
        sync {
            let anchor = load(attributes)
            anchor.dirty()
            return anchor
        }
    }

    public func createBy(cls: Anchor.Type, only: String? = nil) -> Anchor {
        sync {
            let anchor = cls.init(basket: self)
            anchor.iden = generateIden(cls)
            cache[anchor.iden] = anchor
            if let only = only {
                onlyToIden["\(anchor.type!):\(only)"] = anchor.iden
            }
            dirty.insert(anchor)
            return anchor
        }
    }

    private func convert(array: [[String:Any]]) -> [Anchor] {
        sync {
            array.map { attributes in cache[attributes["iden"] as! String] ?? load(attributes) }
        }
    }
    private func convert(array: [[String:Any]], type:Anchor.Type) -> [Anchor] {
        sync {
            array.map { attributes in cache[attributes["iden"] as! String] ?? load(attributes, cls: type) }
        }
    }

    public func selectBy(iden: String) -> Anchor? {
        sync {
            if let anchor = cache[iden] { return anchor }
            guard let attributes = persist.attributes(iden: iden) else { return nil }
            return load(attributes)
        }
    }
    public func selectBy(cls: Anchor.Type, only: String) -> Anchor? {
        sync {
            let type = Loom.name(for: cls)
            if let iden = onlyToIden["\(type):\(only)"], let anchor = cache[iden] { return anchor }
            guard let attributes = persist.attributes(type: type, only: only) else { return nil }
            return load(attributes)
        }
    }
    public func selectOne(where field: String, is value: String, type: Anchor.Type) -> Domain? {
        sync {
            guard let attributes = persist.selectOne(where: field, is: value, type: Loom.name(for: type)) else { return nil }
            return cache[attributes["iden"] as! String] ?? load(attributes, cls: type)
        }
    }
    public func select(where field: String, is value: String, type: Anchor.Type) -> [Domain] {
        let array = persist.select(where: field, is: value, type: Loom.name(for: type))
        return convert(array: array, type:type)
    }
    public func select(type: Anchor.Type, where clause: String, params: [Any]) -> [Domain] {
        convert(array: persist.select(type: Loom.name(for: type), where: clause, params: params), type: type)
    }
    public func count(type: Anchor.Type, where clause: String, params: [Any]) -> Int {
        persist.count(type: Loom.name(for: type), where: clause, params: params)
    }
    public func selectAll(_ type: Anchor.Type) -> [Anchor] {
        let array = persist.selectAll(type: Loom.name(for: type))
        return convert(array: array, type: type)
    }
    public func selectForked() -> [Anchor] {
        let array = persist.selectForked()
        return convert(array: array)
    }
    public func selectForkedMemories() -> [[String:Any]] { persist.selectForkedMemories() }
    
    public func syncPacket() -> [String:Any] {
        var attributes: [String:Any] = [:]

        sync {
            var documents: [[String:Any]] = []
            for anchor in selectForked() {
                if anchor.isUploaded {
                    documents.append(anchor.unload())
                }
            }
            
            attributes["fork"] = persist.get(key: "fork")
            attributes["documents"] = documents
            attributes["deleted"] = [] as [Anchor]
            attributes["memories"] = selectForkedMemories()
        }
        
        return attributes
    }
    
    private func enforceDiscipline(_ anchor: Anchor) {
        guard discipline != .tolerant else { return }
        guard DispatchQueue.getSpecific(key: inTransactKey) != true else { return }
        let message = "Loom: [\(anchor.type ?? "?")] \(anchor.iden ?? "?") was modified outside of a transact. Wrap the mutation in Loom.transact { }."
        if discipline == .strict { fatalError(message) }
        print(message + " The change is in the dirty set and will persist with the next transact's sweep.")
    }

    func dirtyAnchor(_ anchor: Anchor) {
        enforceDiscipline(anchor)
        dirty.insert(anchor)
    }
    func deleteAnchor(_ anchor: Anchor) {
        enforceDiscipline(anchor)
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
    
    /// Commits every outstanding dirty anchor — not just those touched inside the closure.
    /// transact is a basket-wide flush point, not a mutation scope: anchors dirtied outside
    /// any transact are swept in here, and nested calls run inline, joining the outer commit.
    /// Writes are optimistic — anchors flip clean at the snapshot, before the I/O; a failed
    /// commit's rows wait in a pending buffer for the next flush. Deliberate; see LOOM.md.
    public func transact(_ closure: ()->()) {
        if onQueue { closure(); return }

        // The commit rides a ticket enqueued from inside the basket block, so the commit
        // queue receives work in snapshot order by construction — ordering without a lock,
        // and the basket queue is free during the disk I/O. The caller still waits for its
        // own ticket: transact returns only after its commit has landed.
        var ticket: DispatchWorkItem? = nil

        queue.sync {
            autoreleasepool {
                closure()

                var dirty = Set<Anchor>()
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

                var stores: [String:[String:Any]] = [:]
                var deletes: Set<String> = []

                for anchor in dirty {
                    if anchor.status == .deleted {
                        if let only = anchor.only { onlyToIden["\(anchor.type!):\(only)"] = nil }
                        deletes.insert(anchor.iden)
                    } else {
                        if let only = anchor.only { onlyToIden["\(anchor.type!):\(only)"] = anchor.iden }
                        anchor.save()
                        stores[anchor.iden] = anchor.unload()
                    }
                }

                for iden in pendingDeletes where stores[iden] == nil { deletes.insert(iden) }
                for (iden, attributes) in pendingStores where stores[iden] == nil && !deletes.contains(iden) { stores[iden] = attributes }
                pendingStores.removeAll()
                pendingDeletes.removeAll()

                guard stores.count + deletes.count > 0 else { return }

                let work = DispatchWorkItem { [self] in
                    let committed = persist.transact { () -> (Bool) in
                        autoreleasepool {
                            var ok: Bool = true
                            for iden in deletes { ok = persist.delete(iden: iden) && ok }
                            for (iden, attributes) in stores { ok = persist.store(iden: iden, attributes: attributes) && ok }
                            return ok
                        }
                    }
                    if !committed {
                        queue.sync {
                            for (iden, attributes) in stores where pendingStores[iden] == nil { pendingStores[iden] = attributes }
                            pendingDeletes.formUnion(deletes)
                        }
                    }
                }
                commitQueue.async(execute: work)
                ticket = work
            }
        }

        ticket?.wait()
    }
    
    public func clearCache() {
        sync { cache.removeAll() }
    }

    /// Removes duplicate `Document` rows for a type that uses the `Only` column (e.g. `folder`). Clears in-memory maps so the next load matches SQLite.
    public func deduplicateDocumentsWithSharedOnlyKey(type: String) {
        sync {
            persist.deduplicateDocumentsWithSharedOnlyKey(type: type)
            cache.removeAll()
            onlyToIden.removeAll()
        }
    }
    
    public func set(key: String, value: String) { persist.set(key: key, value: value) }
    public func setServer(key: String, value: String) { persist.setServer(key: key, value: value) }
    public func get(key: String) -> String? { persist.get(key: key) }
    public func unset(key: String) { persist.unset(key: key) }
    
    public func show() { persist.show() }
    func showID(_ iden: String) { persist.show(iden) }
    
    public func wipe() {
        sync {
            persist.wipe()
            fork = 0
            cache.removeAll()
            dirty.removeAll()
            dehydrate.removeAll()
            pendingStores.removeAll()
            pendingDeletes.removeAll()
        }
    }
    public func wipeDocuments() {
        sync {
            persist.wipeDocuments()
            fork = 0
            cache.removeAll()
            dirty.removeAll()
            dehydrate.removeAll()
            pendingStores.removeAll()
            pendingDeletes.removeAll()
        }
    }

    public func printDocuments() { persist.show() }
    public func printCensus() { persist.census() }
}

#endif
