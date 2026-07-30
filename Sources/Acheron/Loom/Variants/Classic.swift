//
//  Classic.swift
//  Acheron
//
//  Created by Joe Charlier on 4/23/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

#if !Weave && !os(Linux)

import Foundation

public enum DomainStatus {
    case loading, clean, dirty, deleted
}
public enum DomainAction: String {
    case create, edit, delete, added, removed, load, save, dirty
}

class NotFound {}

public protocol Packable where Self:NSObject {
    init?(_: String)
    func pack() -> String
}

open class Domain: NSObject {
    
    // Properties
    @objc public dynamic var iden: String!
    @objc public dynamic var type: String!
    @objc public dynamic var modified: Date!
    
    // Transient
    weak public var parent: Domain?
    private var _status: DomainStatus = .loading
    public var status: DomainStatus {
        set {
            objc_sync_enter(self)
            defer {objc_sync_exit(self)}

            guard _status != newValue else { return }
            
            if _status == .loading && newValue == .dirty {
                
            } else if (_status == .loading || status == .dirty) && newValue == .clean {
                subscribe()
                
            } else if _status == .clean && (newValue == .dirty || newValue == .deleted) {
                unsubscribe()
                
            } else if (_status == .clean || _status == .dirty) && newValue == .deleted {
                
            } else {
                print("Loom transition error: [\((String(describing: Swift.type(of: self))))] \(iden ?? "?") moving from \(_status) to \(newValue)")
            }

            _status = newValue

            if _status == .clean && isStatic == false && subscribed == false {
                fatalError("Loom: [\(String(describing: Swift.type(of: self)))] \(iden ?? "?") became .clean without an active KVO subscription. A stale Domain has re-entered the lifecycle: it was deleted or removed from its Anchor's graph, but something still holds it and tried to save or load it. If it was removed with remove(_:), also remove it from its parent's children array so save() no longer reaches it. Domain objects should not be held after they leave their Anchor's graph.")
            }
        }
        get {
            objc_sync_enter(self)
            defer {objc_sync_exit(self)}
            return _status
        }
    }
    
    var subscribed: Bool = false
    
    // Inits
    public override init() {
        self.iden = UUID().uuidString
        self.type = Loom.nameFromType(Swift.type(of: self))
        super.init()
        create()
    }
    public init(parent: Domain) {
        self.iden = UUID().uuidString
        self.type = Loom.nameFromType(Swift.type(of: self))
        self.parent = parent
        super.init()
        load()
    }
    public required init(attributes: [String:Any], parent: Domain? = nil) {
        self.iden = attributes["iden"] as? String
        self.type = attributes["type"] as? String
        self.parent = parent
        super.init()
    }
    
    deinit { if status == .clean { unsubscribe() } }
    
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

        // Single Domain instances stored as properties (e.g. engineer.jdWatson, jdWatson.quests).
        // Without this walk, save()/delete()/deepSearchChildren never reach property-level Domains,
        // which leaves them stuck in .dirty status after the first edit() — which means their KVO
        // observers stay unsubscribed and subsequent mutations never propagate. We only walk
        // properties that respond directly to the selector (matches unload()'s responds-to check;
        // properties stored under a `Proxy` suffix or non-KVC keys aren't Domain instances).
        properties.forEach {
            guard responds(to: NSSelectorFromString($0)) else { return }
            if let domain = value(forKey: $0) as? Domain {
                result.append(domain)
            }
        }

        // Arrays of Domains stored under `children` (e.g. engineer.creations).
        children.forEach {
            guard let domains = self.value(forKeyPath: $0) as? [Domain] else { return }
            result += domains
        }

        return result
    }
    func deepSearchChildren(_ search: (Domain)->(Bool)) -> Set<Domain> {
        var result: Set<Domain> = []
        if search(self) { result.insert(self) }
        allDomainChildren.forEach { result.formUnion($0.deepSearchChildren(search)) }
        return result
    }
    private func classForKeyPath(_ keyPath: String) -> AnyClass? {
        var cls: AnyClass? = Loom.cachedClass(type: type, keyPath: keyPath)
        if cls == nil {
            cls = Loom.classForKeyPath(keyPath: keyPath, parent: Swift.type(of:self))
            Loom.cacheClass(cls ?? NotFound.self, type: type, keyPath: keyPath)
        }
        if cls === NotFound.self { cls = nil }
        return cls
    }
    private func arrayClassForKeyPath(_ keyPath: String) -> AnyClass? {
        var cls: AnyClass? = Loom.cachedArrayClass(type: type, keyPath: keyPath)
        if cls == nil {
            cls = Loom.arrayClassForKeyPath(keyPath: keyPath, parent: self)
            Loom.cacheArrayClass(cls ?? NotFound.self, type: type, keyPath: keyPath)
        }
        if cls === NotFound.self { cls = nil }
        return cls
    }

    private func subscribe() {
        if isStatic { return }
        properties.forEach { addObserver(self, forKeyPath: $0, options: [.new,.old], context: nil) }
        subscribed = true
    }
    private func unsubscribe() {
        if isStatic { return }
        properties.forEach { removeObserver(self, forKeyPath: $0) }
        subscribed = false
    }
    
    private func handleTriggers(_ domain: Domain, action: DomainAction) {
        guard let basket = domain.anchor?.basket else { return }
        basket.blocksFor(class: Swift.type(of: domain), action: action).forEach { $0(domain) }
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
            let value: Any?
            if responds(to: NSSelectorFromString(keyPath)) {
                value = self.value(forKeyPath: keyPath)
            } else {
                value = self.value(forKeyPath: "\(keyPath)Proxy")
            }
            let unloader = self.unloader(keyPath:keyPath)
            if let unloader = unloader {
                if let value { attributes[keyPath] = unloader(value) }
            } else if let value = value as? Date {
                attributes[keyPath] = value.toISOFormattedString() as NSString
            } else if let value = value as? Packable {
                attributes[keyPath] = value.pack()
            } else if let value = value as? Domain {
                attributes[keyPath] = value.unload() as NSDictionary
            } else if let value = value as? [Domain] {
                var array: [Any] = []
                value.forEach { array.append($0.unload()) }
                attributes[keyPath] = array as NSArray;
            } else if let value = value as? [Packable] {
                var array: [Any] = []
                value.forEach { array.append($0.pack()) }
                attributes[keyPath] = array as NSArray;
            } else {
                attributes[keyPath] = value
            }
        }
        for keyPath in children {
            let domains = value(forKeyPath: keyPath) as! [Any]
            if domains.count == 0 {
                attributes.removeValue(forKey: keyPath)
                continue
            }
            var array: [Any] = []
            if let domains = domains as? [Domain] {
                domains.forEach { array.append($0.unload()) }
            } else if let packables = domains as? [Packable] {
                packables.forEach { array.append($0.pack()) }
            } else if let strings = domains as? [String] {
                strings.forEach { array.append($0) }
            }
            attributes[keyPath] = array as NSArray;
        }
        
        return attributes
    }
    public func toJSON() -> String { unload().toJSON() }
    
    private func indexOfChildren(_ keyPath: String) -> [String:Domain] {
        var index: [String:Domain] = [:]
        let domains = value(forKeyPath: keyPath) as! [Domain]
        domains.forEach { index[$0.iden] = $0 }
        return index
    }
    private func isOptional(_ instance: Any) -> Bool {
        let mirror = Mirror(reflecting: instance)
        let style = mirror.displayStyle
        return style == .optional
    }
    public func load(attributes: [String:Any], replicate: Bool = false) {
        // Properties
        for keyPath in properties {
            guard !(replicate && keyPath == "iden") else { iden = UUID().uuidString; continue }
            var value = attributes[keyPath]
            if value != nil {
                let loader = self.loader(keyPath:keyPath)
                if let loader = loader {
                    let newValue = loader(value!)
                    if let newValue = newValue {
                        value = newValue
                    } else {
                        value = NSNumber(value: 0)
                    }
                } else {
                    let cls: AnyClass? = classForKeyPath(keyPath)
                    if cls == NSDate.self {
                        if let string = value as? String, let date = Date.fromISOFormatted(string: string) ?? Double(string).map({ Date(timeIntervalSinceReferenceDate: $0) }) {
                            value = date
                        } else {
                            value = nil
                        }
                    } else if let cls = cls as? Packable.Type {
                        value = cls.init(value as! String)
                    } else if cls?.superclass() == Domain.self {
                        let valueAtts = value as! [String:Any]
                        let cls = Loom.classForType(valueAtts["type"] as! String) as! Domain.Type
                        let domain = cls.init(attributes: valueAtts, parent: self)
                        domain.load(attributes:valueAtts, replicate: replicate)
                        load(domain)
                        value = domain;
                    } else if let cls = arrayClassForKeyPath(keyPath) as? Domain.Type {
                        var array: [Any] = []
                        let existing = indexOfChildren(keyPath)
                        for child in value as! [[String:Any]] {
                            var domain: Domain? = existing[child["iden"] as! String]
                            if domain == nil {
                                domain = cls.init(attributes: child, parent: self)
                            }
                            domain!.load(attributes:child, replicate: replicate)
                            load(domain!)
                            array.append(domain!)
                        }
                        value = array
                    } else if let cls = arrayClassForKeyPath(keyPath) as? Packable.Type {
                        var array: [Any] = []
                        for package in value as! [String] {
                            guard let row = cls.init(package) else { continue }
                            array.append(row)
                        }
                        value = array
                    }
                }
            }
            
            if value != nil {
                if responds(to: NSSelectorFromString(keyPath)) {
                    setValue(value, forKey: keyPath)
                } else {
                    setValue(value, forKey: "\(keyPath)Proxy")
                }
            }
            else {
                if let currentValue = self.value(forKeyPath: keyPath) as Any? {
                    if isOptional(currentValue) {
                        setValue(nil, forKey: keyPath)
                    }
                }
            }
        }
        // Children
        for keyPath in children {
            
            let children = attributes[keyPath] as! [Any]?
            if let children = children  {
                if children.count == 0 {continue}
                
                var array: [Any] = []
                
                if children.first is [String:Any] {
                    let existing = indexOfChildren(keyPath)
                    for child in children as! [[String:Any]] {
                        var domain: Domain? = existing[child["iden"] as! String]
                        if domain == nil {
                            let cls = Loom.classForType(child["type"] as! String) as! Domain.Type
                            domain = cls.init(attributes: child, parent: self)
                        }
                        domain!.load(attributes:child, replicate: replicate)
                        load(domain!)
                        array.append(domain!)
                    }
                } else if let cls = arrayClassForKeyPath(keyPath) as? Packable.Type {
                    for package in children as! [String] {
                        guard let row = cls.init(package) else { continue }
                        array.append(row)
                    }
                } else {
                    for string in children as! [String] {
                        array.append(string)
                    }
                }
                setValue(array, forKey: keyPath)
            }
        }
        load()
    }
    public func dirtyUsingAttributes(_ attributes: [String:Any]) {
        dirty()
        deepSearchChildren({ (domain) -> (Bool) in return true }).forEach { $0.dirty() }
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
    open var children: [String] { []  }
    var isStatic: Bool { false }
    public var anchor: Anchor? {
        get { return parent?.anchor }
    }
    
// NSObject ========================================================================================
    // No-op writes are suppressed. Beyond filtering redundant edits, this is what makes a
    // wholesale reload cheap: a mirror-style refresh (e.g. AepX's BootPond) rewrites every
    // property of every anchor, but only anchors whose data actually changed get dirtied
    // and persisted — the equality check is the diff engine.
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        let oldValue = change?[.oldKey] as? NSObject
        let newValue = change?[.newKey] as? NSObject
        if newValue != oldValue { edit() }
    }
}

// ================================================================================================

open class Anchor: Domain {
    @objc public dynamic var fork: Int = 0
    @objc public dynamic var vers: Int = 0
    
    public unowned var basket: Basket? = nil
    
    public override init() {
        super.init()
    }
    public required init(attributes: [String : Any], parent: Domain? = nil) {
        super.init(attributes: attributes, parent: parent)
    }
    public required init(basket: Basket) {
        self.basket = basket
        super.init()
    }
    public required init(basket: Basket, attributes: [String:Any]) {
        self.basket = basket
        super.init(attributes: attributes)
    }
    
    var only: String? {
        guard let basket = basket, let key = basket.only(type: type) else { return nil }
        return value(forKey: key) as? String
    }
    
    public func resolveConflicts(_ attributes: [String:Any]) {}
    
// Actions =========================================================================================
    override func create() {
        super.create()
        if let basket = basket { fork = basket.fork + 1 }
    }
    override func edit() {
        super.edit()
        if let basket = basket { fork = basket.fork + 1 }
        basket?.dirtyAnchor(self)
    }
    public override func delete()  {
        super.delete()
        basket?.deleteAnchor(self)
    }
    override func dirty() {
        super.dirty()
        basket?.dirtyAnchor(self)
    }
    
// Anchor ==========================================================================================
    open var isUploaded: Bool { true }
    
// Domain ==========================================================================================
    public override var anchor: Anchor {
        get { return self }
    }
    override open var properties: [String] { super.properties + ["fork", "vers"] }
}

// ================================================================================================

public class Loom {
    public static var basket: Basket!

    public static var namespaces: [String] = []

    // keyPath → class memos. Two namespaces: for an array property, classForKeyPath resolves
    // the objc attribute type (NSArray) while arrayClassForKeyPath resolves the element class —
    // same type and keyPath, different answers, so they must not share a slot.
    private static var domains = [String:[String:AnyClass]]()
    private static var arrayDomains = [String:[String:AnyClass]]()
    private static let domainsQueue = DispatchQueue(label: "Loom.domains")

    static func cachedClass(type: String, keyPath: String) -> AnyClass? {
        domainsQueue.sync { domains[type]?[keyPath] }
    }
    static func cacheClass(_ cls: AnyClass, type: String, keyPath: String) {
        domainsQueue.sync { domains[type, default: [:]][keyPath] = cls }
    }
    static func cachedArrayClass(type: String, keyPath: String) -> AnyClass? {
        domainsQueue.sync { arrayDomains[type]?[keyPath] }
    }
    static func cacheArrayClass(_ cls: AnyClass, type: String, keyPath: String) {
        domainsQueue.sync { arrayDomains[type, default: [:]][keyPath] = cls }
    }

    static func name(for type: Domain.Type) -> String { nameFromType(type) }
    static func nameFromType(_ type: Domain.Type) -> String {
        let fullname: String = NSStringFromClass(type)
        let name = String(fullname[fullname.range(of: ".")!.upperBound...])
        return name[0...0].lowercased()+name[1...]
    }
    static func classFromName(_ name: String) -> AnyClass? {
        var cls: AnyClass? = nil
        for namespace in Loom.namespaces {
            let fullname = namespace + "." + name[0...0].uppercased()+name[1...]
            cls =  NSClassFromString(fullname)
            if cls != nil { break }
        }
        return cls
    }
    static func classForType(_ name: String) -> AnyClass {
        guard let cls: AnyClass = classFromName(name) else {
            fatalError("Loom: no class found for type '\(name)' in namespaces \(namespaces); if the class was renamed or removed, documents of this type can no longer load — restore the class or migrate the rows.")
        }
        return cls
    }
    
    public static func classForKeyPath(keyPath: String, parent: Domain.Type) -> AnyClass? {
        var n: UInt32 = 0
        var cls: AnyClass?

        // class_copyPropertyList returns NULL when the class has no @objc properties.
        // That's a valid state — we still need to recurse to the superclass below.
        if let properties: UnsafeMutablePointer<objc_property_t> = class_copyPropertyList(parent, &n) {
            for i in 0..<Int(n) {
                let name = String(validatingUTF8: property_getName(properties[i]))
                if keyPath != name { continue }

                let attributes: UnsafePointer<Int8> = property_getAttributes(properties[i])!
                if attributes[1] == Int8(UInt8(ascii:"@")) {
                    var className: String = String()
                    var j = 3
                    while attributes[j] != 0 && attributes[j] != Int8(UInt8(ascii:"\"")) {
                        className.append(Character(UnicodeScalar(UInt8(attributes[j]))))
                        j += 1
                    }
                    cls = NSClassFromString(className)
                }
                break
            }
            free(properties)
        }

        if cls == nil {
            let superclass: NSObject.Type = class_getSuperclass(parent) as! NSObject.Type
            if superclass != NSObject.self {
                cls = classForKeyPath(keyPath: keyPath, parent: superclass as! Domain.Type)
            }
        }

        return cls
    }
    public static func arrayClassForKeyPath(keyPath: String, parent: AnyObject) -> AnyClass? {
        let mirror: Mirror = Mirror(reflecting: parent)
        for property in mirror.children {
            guard property.label! == keyPath else {continue}
            var className = "\(Swift.type(of: property.value))"
            if className.starts(with: "Array<") {
                className.removeLast(1)
                className.removeFirst(6)
                // Mirror may emit "Pachinko.Message" — NSClassFromString needs "Message" + namespace prefix only.
                if let dot = className.lastIndex(of: ".") {
                    className = String(className[className.index(after: dot)...])
                }
                for namespace in Loom.namespaces {
                    if let cls = NSClassFromString("\(namespace).\(className)") {
                        return cls
                    }
                }
            }
            return nil
        }
        return nil
    }
    
    public static func domain(attributes: [String:Any], parent: Domain? = nil, replicate: Bool = false) -> Domain {
        let cls = Loom.classForType(attributes["type"] as! String) as! Domain.Type
        let domain: Domain = cls.init(attributes: attributes, parent: parent)
        domain.load(attributes:attributes, replicate: replicate)
        return domain
    }
    
    public static func set(key: String, value: String) { Loom.basket.set(key: key, value: value) }
    public static func get(key: String) -> String? { Loom.basket.get(key: key) }
    public static func unset(key: String) { Loom.basket.unset(key: key) }
    public static func create<T: Anchor>(only: String? = nil) -> T { Loom.basket.createBy(cls: T.self, only: only) as! T }
    
    public static func selectBy<T: Anchor>(iden: String) -> T? { Loom.basket.selectBy(iden: iden) as? T }
    public static func selectBy<T: Anchor>(only: String) -> T? { Loom.basket.selectBy(cls: T.self, only: only) as? T }
    public static func selectOne<T: Anchor>(where field: String, is value: String) -> T? { Loom.basket.selectOne(where: field, is: value, type: T.self) as? T }
    public static func select<T: Anchor>(where field: String, is value: String) -> [T] { Loom.basket.select(where: field, is: value, type: T.self) as! [T] }
    public static func select<T: Anchor>(where clause: String, _ params: [Any] = []) -> [T] { Loom.basket.select(type: T.self, where: clause, params: params) as! [T] }
    public static func count(_ type: Anchor.Type, where clause: String = "", _ params: [Any] = []) -> Int { Loom.basket.count(type: type, where: clause, params: params) }
    public static func selectAll<T: Anchor>() -> [T] { Loom.basket.selectAll(T.self) as! [T] }
    
    public static func transact(_ closure: ()->()) { Loom.basket.transact(closure) }
    public static func transact(_ closure: @escaping ()->()) async { await Loom.basket.transact(closure) }

    /// Deletes extra persisted rows that share the same `Type` + `Only` (e.g. duplicate folders). Safe to call at launch.
    public static func deduplicateDocumentsWithSharedOnlyKey(type: String) {
        Loom.basket.deduplicateDocumentsWithSharedOnlyKey(type: type)
    }
    
    public static func start(basket: Basket, namespaces: [String]) {
        Loom.basket = basket
        Loom.namespaces = namespaces
    }
}

#endif
