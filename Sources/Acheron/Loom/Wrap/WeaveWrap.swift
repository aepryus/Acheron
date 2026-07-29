//
//  Weave.swift
//  Acheron
//
//  Created by Joe Charlier on 7/29/26.
//  Copyright © 2026 Aepryus Software. All rights reserved.
//

#if !Weave && os(Linux)

import Foundation

final class LoomBox<Value> {
    var value: Value
    init(_ value: Value) { self.value = value }
}

protocol LoomWrapped {
    func loomGet() -> Any?
    func loomSet(_ raw: Any?, on domain: Domain)
}

@propertyWrapper public struct Field<Value> {
    let box: LoomBox<Value>
    public init(wrappedValue: Value) { box = LoomBox(wrappedValue) }

    @available(*, unavailable, message: "@Field only works inside a Domain")
    public var wrappedValue: Value {
        get { fatalError() }
        set { fatalError() }
    }

    public static subscript<E: Domain>(
        _enclosingInstance instance: E,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<E, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<E, Field<Value>>
    ) -> Value {
        get { instance[keyPath: storageKeyPath].box.value }
        set {
            let box = instance[keyPath: storageKeyPath].box
            let oldValue = box.value
            box.value = newValue
            instance.loomFieldDidSet(oldValue, newValue)
        }
        _modify {
            let box = instance[keyPath: storageKeyPath].box
            yield &box.value
            instance.loomDidMutate()
        }
    }
}
extension Field: LoomWrapped {
    func loomGet() -> Any? { box.value }
    func loomSet(_ raw: Any?, on domain: Domain) {
        guard let converted = domain.loomConvert(raw, current: box.value, type: Value.self) as? Value else { return }
        box.value = converted
    }
}

@propertyWrapper public struct Child<Value> {
    let box: LoomBox<Value>
    public init(wrappedValue: Value) { box = LoomBox(wrappedValue) }

    @available(*, unavailable, message: "@Child only works inside a Domain")
    public var wrappedValue: Value {
        get { fatalError() }
        set { fatalError() }
    }

    public static subscript<E: Domain>(
        _enclosingInstance instance: E,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<E, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<E, Child<Value>>
    ) -> Value {
        get { instance[keyPath: storageKeyPath].box.value }
        set {
            let box = instance[keyPath: storageKeyPath].box
            let oldValue = box.value
            box.value = newValue
            instance.loomChildDidSet(oldValue, newValue)
        }
    }
}
extension Child: LoomWrapped {
    func loomGet() -> Any? { box.value }
    func loomSet(_ raw: Any?, on domain: Domain) {
        guard let converted = domain.loomConvert(raw, current: box.value, type: Value.self) as? Value else { return }
        box.value = converted
    }
}

// Runtime type recovery ===========================================================================
protocol LoomChildren {
    static func loomMerge(_ raw: Any?, current: Any, parent: Domain) -> Any
}
extension Array: LoomChildren where Element: Domain {
    static func loomMerge(_ raw: Any?, current: Any, parent: Domain) -> Any {
        parent.loomChildren(raw, current: current as! [Element], parent: parent)
    }
}

protocol LoomPacked {
    static func loomUnpack(_ raw: Any?) -> Any?
}
extension Array: LoomPacked where Element: Packable {
    static func loomUnpack(_ raw: Any?) -> Any? {
        (raw as? [String]).map { $0.compactMap { Element($0) } }
    }
}

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

extension Equatable {
    func loomIsEqual(_ other: Any) -> Bool { (other as? Self).map { $0 == self } ?? false }
}
func loomEquals(_ a: Any, _ b: Any) -> Bool {
    switch (a, b) {
        case let (a as String, b as String): return a == b
        case let (a as Int, b as Int): return a == b
        case let (a as Double, b as Double): return a == b
        case let (a as Bool, b as Bool): return a == b
        default:
            guard let a = a as? any Equatable else { return false }
            return a.loomIsEqual(b)
    }
}

#endif
