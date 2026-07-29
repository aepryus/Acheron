//
//  Anchor.swift
//  Acheron
//
//  Created by Joe Charlier on 4/23/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

#if !os(Linux)

import Acheron
import Foundation

open class Anchor: Domain {
    public var fork: Int = 0
    public var vers: Int = 0

    public unowned var basket: Basket? = nil

    public override init() {
        super.init()
    }
    public required init(attributes: [String:Any], parent: Domain? = nil) {
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
        return loomGet(key) as? String
    }

    public func resolveConflicts(_ attributes: [String:Any]) {}

// Field access ====================================================================================
    override open func loomGet(_ field: String) -> Any? {
        switch field {
            case "fork": return fork
            case "vers": return vers
            default: return super.loomGet(field)
        }
    }
    override open func loomSet(_ field: String, _ value: Any?) {
        switch field {
            case "fork": fork = (value as? Int) ?? (value as? NSNumber)?.intValue ?? fork
            case "vers": vers = (value as? Int) ?? (value as? NSNumber)?.intValue ?? vers
            default: super.loomSet(field, value)
        }
    }

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

#endif
