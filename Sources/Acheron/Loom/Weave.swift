//
//  Weave.swift
//  Acheron
//
//  Created by Joe Charlier on 7/29/26.
//  Copyright © 2026 Aepryus Software. All rights reserved.
//

import Foundation

@attached(member, names: named(properties), named(children), named(loomGet), named(loomSet))
public macro Woven() = #externalMacro(module: "AcheronMacros", type: "WovenMacro")

@attached(accessor, names: named(init), named(get), named(set))
@attached(peer, names: prefixed(`_`))
public macro Field() = #externalMacro(module: "AcheronMacros", type: "FieldMacro")

@attached(accessor, names: named(init), named(get), named(set))
@attached(peer, names: prefixed(`_`))
public macro Kids() = #externalMacro(module: "AcheronMacros", type: "KidsMacro")

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
