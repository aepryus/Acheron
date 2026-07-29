//
//  Domain.swift
//  Acheron
//
//  Created by Joe Charlier on 4/23/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

#if !os(Linux)

import Foundation

public enum DomainStatus {
    case loading, clean, dirty, deleted
}
public enum DomainAction: String {
    case create, edit, delete, added, removed, load, save, dirty
}

public protocol Packable {
    init?(_: String)
    func pack() -> String
}

open class Domain: Hashable {

    // Properties
    public var iden: String!
    public var type: String!
    public var modified: Date!

    // Transient
    weak public var parent: Domain?
    var replicating: Bool = false
    private let statusLock = NSLock()
    private var _status: DomainStatus = .loading
    public var status: DomainStatus {
        set {
            guard _status != newValue else { return }

            statusLock.lock()
            defer { statusLock.unlock() }

            let legal = (_status == .loading && newValue == .dirty)
                || ((_status == .loading || _status == .dirty) && newValue == .clean)
                || (_status == .clean && (newValue == .dirty || newValue == .deleted))
                || ((_status == .clean || _status == .dirty) && newValue == .deleted)
            if !legal { print("Loom transition error: [\(String(describing: Swift.type(of: self)))] \(iden ?? "?") moving from \(_status) to \(newValue)") }

            _status = newValue
        }
        get { return _status }
    }

    // Inits
    public init() {
        self.iden = UUID().uuidString
        self.type = Loom.name(for: Swift.type(of: self))
        create()
    }
    public init(parent: Domain) {
        self.iden = UUID().uuidString
        self.type = Loom.name(for: Swift.type(of: self))
        self.parent = parent
        load()
    }
    public required init(attributes: [String:Any], parent: Domain? = nil) {
        self.iden = attributes["iden"] as? String
        self.type = attributes["type"] as? String
        self.parent = parent
    }

    // Methods
    func load(_ domain: Domain) {
        domain.parent = self
        domain.onLoaded()
    }
    public func add(_ domain: Domain) {
        load(domain)
        domain.onAdded()
        edit()
        domain.handleTriggers(self, action: .added)
    }
    public func remove(_ domain: Domain) {
        domain.onRemoved()
        domain.delete()
        edit()
        domain.handleTriggers(domain, action: .removed)
    }

    var allDomainChildren: [Domain] {
        var result: [Domain] = []
        properties.forEach {
            if let domain = flatten(loomGet($0)) as? Domain { result.append(domain) }
        }
        children.forEach {
            if let domains = loomGet($0) as? [Domain] { result += domains }
        }
        return result
    }
    func deepSearchChildren(_ search: (Domain)->(Bool)) -> Set<Domain> {
        var result: Set<Domain> = []
        if search(self) { result.insert(self) }
        allDomainChildren.forEach { result.formUnion($0.deepSearchChildren(search)) }
        return result
    }

    private func handleTriggers(_ domain: Domain, action: DomainAction) {
        guard let basket = domain.anchor?.basket else { return }
        basket.blocksFor(class: Swift.type(of: domain), action: action).forEach { $0(domain) }
    }

// Field access ====================================================================================
    open func loomGet(_ field: String) -> Any? {
        switch field {
            case "iden": return iden
            case "type": return type
            case "modified": return modified
            default: return nil
        }
    }
    open func loomSet(_ field: String, _ value: Any?) {
        switch field {
            case "iden": iden = value as? String ?? iden
            case "type": type = value as? String ?? type
            case "modified": if let date = Loom.date(from: value) { modified = date }
            default: break
        }
    }

// Capture =========================================================================================
    func loomCapture() {
        guard status == .clean else { return }
        edit()
    }
    public func loomDidSet<T: Equatable>(_ old: T, _ new: T) { if old != new { loomCapture() } }
    public func loomDidSet<T>(_ old: T, _ new: T) { loomCapture() }
    public func loomDidSetChildren<T: Domain>(_ old: [T], _ new: [T]) { if old != new { loomCapture() } }

// Conversion ======================================================================================
    private func flatten(_ value: Any?) -> Any? {
        guard let value else { return nil }
        if let optional = value as? LoomOptional { return optional.loomWrapped }
        return value
    }
    public func loomConvert<T>(_ raw: Any?, current: T, parent: Domain) -> T {
        if let optionalType = T.self as? LoomOptional.Type {
            guard let raw, !(raw is NSNull) else { return optionalType.loomNil as! T }
            let currentInner = (current as! LoomOptional).loomWrapped
            guard let converted = loomConvertInner(raw, type: optionalType.loomWrappedType, current: currentInner) else { return optionalType.loomNil as! T }
            return optionalType.loomWrap(converted) as! T
        }
        guard let raw, !(raw is NSNull) else { return current }
        return (loomConvertInner(raw, type: T.self, current: current) as? T) ?? current
    }
    private func loomConvertInner(_ raw: Any, type: Any.Type, current: Any?) -> Any? {
        if type == Date.self { return Loom.date(from: raw) }
        if let packableType = type as? Packable.Type {
            guard let string = raw as? String else { return current }
            return packableType.init(string)
        }
        if type is Domain.Type {
            guard let attributes = raw as? [String:Any] else { return current }
            let cls = Loom.classForType(attributes["type"] as! String)
            let domain = cls.init(attributes: attributes, parent: self)
            domain.load(attributes: attributes, replicate: replicating)
            load(domain)
            return domain
        }
        if type == Int.self { return (raw as? Int) ?? (raw as? NSNumber)?.intValue }
        if type == Double.self { return (raw as? Double) ?? (raw as? NSNumber)?.doubleValue }
        if type == Bool.self { return (raw as? Bool) ?? (raw as? NSNumber)?.boolValue }
        return raw
    }
    public func loomChildren<T: Domain>(_ raw: Any?, current: [T], parent: Domain) -> [T] {
        guard let list = raw as? [[String:Any]], !list.isEmpty else { return current }
        var index: [String: T] = [:]
        current.forEach { index[$0.iden] = $0 }
        var result: [T] = []
        for attributes in list {
            let child: T
            if let existing = index[attributes["iden"] as! String] { child = existing }
            else { child = Loom.classForType(attributes["type"] as! String).init(attributes: attributes, parent: self) as! T }
            child.load(attributes: attributes, replicate: replicating)
            load(child)
            result.append(child)
        }
        return result
    }

// Actions =========================================================================================
    func create() {
        status = .dirty
        modified = Date()
        onCreate()
        handleTriggers(self, action: .create)
    }
    func edit() {
        dirty()
        modified = Date()
        onEdit()
        handleTriggers(self, action: .edit)
        parent?.edit()
    }
    public func delete() {
        status = .deleted
        modified = Date()
        onDelete()
        handleTriggers(self, action: .delete)
        allDomainChildren.forEach { $0.delete() }
    }

    func dirty() {
        guard status != .deleted else { return }
        status = .dirty
    }
    func dirtied() {
        onDirty()
        handleTriggers(self, action: .dirty)
    }

    func load() {
        status = .clean
        onLoad()
        handleTriggers(self, action: .load)
    }
    func save() {
        status = .clean
        onSave()
        handleTriggers(self, action: .save)
        allDomainChildren.forEach { $0.save() }
    }

// Events ==========================================================================================
    open func onCreate() {}
    open func onEdit() {}
    open func onDelete() {}

    open func onLoaded() {}
    open func onAdded() {}
    open func onRemoved() {}

    open func onInit() {}
    open func onDirty() {}

    open func onSave() {}
    open func onLoad() {}

// Load and Unload =================================================================================
    open func loader(keyPath: String) -> ((Any)->(Any?))? { nil }
    open func unloader(keyPath: String) -> ((Any)->(Any?))? { nil }

    public func unload() -> [String:Any] {
        var attributes: [String:Any] = [:]

        for keyPath in properties {
            let value: Any? = flatten(loomGet(keyPath))
            if let unloader = self.unloader(keyPath: keyPath) {
                if let value { attributes[keyPath] = unloader(value) }
            } else if let value = value as? Date {
                attributes[keyPath] = value.toISOFormattedString()
            } else if let value = value as? Packable {
                attributes[keyPath] = value.pack()
            } else if let value = value as? Domain {
                attributes[keyPath] = value.unload()
            } else if let value = value as? [Domain] {
                attributes[keyPath] = value.map { $0.unload() }
            } else if let value = value as? [Packable] {
                attributes[keyPath] = value.map { $0.pack() }
            } else if let value {
                attributes[keyPath] = value
            }
        }
        for keyPath in children {
            guard let domains = loomGet(keyPath) else { continue }
            if let domains = domains as? [Domain] {
                if domains.count == 0 { continue }
                attributes[keyPath] = domains.map { $0.unload() }
            } else if let packables = domains as? [Packable] {
                if packables.count == 0 { continue }
                attributes[keyPath] = packables.map { $0.pack() }
            } else if let strings = domains as? [String] {
                if strings.count == 0 { continue }
                attributes[keyPath] = strings
            }
        }

        return attributes
    }
    public func toJSON() -> String { unload().toJSON() }

    public func load(attributes: [String:Any], replicate: Bool = false) {
        replicating = replicate
        if replicate { iden = UUID().uuidString }
        for keyPath in properties {
            guard !(replicate && keyPath == "iden") else { continue }
            var raw = attributes[keyPath]
            if let loader = self.loader(keyPath: keyPath), let value = raw { raw = loader(value) }
            loomSet(keyPath, raw)
        }
        for keyPath in children {
            loomSet(keyPath, attributes[keyPath])
        }
        replicating = false
        load()
    }
    public func dirtyUsingAttributes(_ attributes: [String:Any]) {
        dirty()
        deepSearchChildren({ _ in true }).forEach { $0.dirty() }
        load(attributes: attributes)
    }
    public func dirtyUsingDomain(_ domain: Domain) {
        dirtyUsingAttributes(domain.unload())
    }
    public func editUsingAttributes(_ attributes: [String:Any]) {
        edit()
        load(attributes: attributes)
    }
    public func editUsingDomain(_ domain: Domain) {
        editUsingAttributes(domain.unload())
    }

// Domain ==========================================================================================
    open var properties: [String] { ["iden", "type", "modified"] }
    open var children: [String] { [] }
    var isStatic: Bool { false }
    public var anchor: Anchor? {
        get { return parent?.anchor }
    }

// Hashable ========================================================================================
    public static func == (lhs: Domain, rhs: Domain) -> Bool { lhs === rhs }
    public func hash(into hasher: inout Hasher) { hasher.combine(ObjectIdentifier(self)) }
}

#endif
