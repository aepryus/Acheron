//
//  Loom.swift
//  Acheron
//
//  Created by Joe Charlier on 4/23/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//
//  Before proposing structural changes to Loom, read LOOM.md in this directory.
//

#if Weave || os(Linux)

import Foundation

#if Weave

@attached(member, names: named(properties), named(children), named(loomGet), named(loomSet))
public macro Domain() = #externalMacro(module: "AcheronMacros", type: "DomainMacro")

@attached(accessor, names: named(init), named(get), named(set))
@attached(peer, names: prefixed(`_`))
public macro Field() = #externalMacro(module: "AcheronMacros", type: "FieldMacro")

@attached(accessor, names: named(init), named(get), named(set))
@attached(peer, names: prefixed(`_`))
public macro Child() = #externalMacro(module: "AcheronMacros", type: "ChildMacro")

public protocol LoomOptional {
    static var loomNil: Self { get }
    static var loomWrappedType: Any.Type { get }
    var loomWrapped: Any? { get }
    static func loomWrap(_ value: Any) -> Self
}
extension Optional: LoomOptional {
    public static var loomNil: Optional<Wrapped> { .none }
    public static var loomWrappedType: Any.Type { Wrapped.self }
    public var loomWrapped: Any? { self }
    public static func loomWrap(_ value: Any) -> Optional<Wrapped> { value as? Wrapped }
}

#endif

public class Loom {
    public static var basket: Basket!

    private static var types: [String: Domain.Type] = [:]

    public static func register(_ list: [Domain.Type]) {
        list.forEach { types[name(for: $0)] = $0 }
    }
    static func name(for type: Domain.Type) -> String {
        let name = String(describing: type)
        return name[0...0].lowercased() + name[1...]
    }
    static func classFromName(_ name: String) -> Domain.Type? { types[name] }
    static func classForType(_ name: String) -> Domain.Type {
        guard let cls = types[name] else {
            fatalError("Loom: no class registered for type '\(name)'; register it in Loom.start(basket:types:) — if the class was renamed or removed, documents of this type can no longer load; restore the class or migrate the rows.")
        }
        return cls
    }

    static func date(from raw: Any?) -> Date? {
        guard let raw else { return nil }
        if let date = raw as? Date { return date }
        guard let string = raw as? String else { return nil }
        return Date.fromISOFormatted(string: string) ?? Double(string).map { Date(timeIntervalSinceReferenceDate: $0) }
    }

    public static func domain(attributes: [String:Any], parent: Domain? = nil, replicate: Bool = false) -> Domain {
        let cls = Loom.classForType(attributes["type"] as! String)
        let domain: Domain = cls.init(attributes: attributes, parent: parent)
        domain.load(attributes: attributes, replicate: replicate)
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

    public static func start(basket: Basket, types: [Domain.Type]) {
        Loom.basket = basket
        Loom.register(types)
    }
}

#endif
