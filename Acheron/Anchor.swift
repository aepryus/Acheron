//
//  Anchor.swift
//  Acheron
//
//  Created by Joe Charlier on 4/23/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import Foundation

open class Anchor: Domain {
	@objc public dynamic var fork: Int = 0
	@objc public dynamic var vers: Int = 0
	
	public unowned var basket: Basket? = nil
	
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
		guard let basket = basket, let key = basket.only(type: type) else {return nil}
		return value(for: key) as? String
	}
	
	public func resolveConflicts(_ attributes: [String:Any]) {}
	
// Actions =========================================================================================
	override func create() {
		super.create()
		
		guard let basket = basket else {return}
		fork = basket.fork + 1
	}
	override func edit() {
		super.edit()
		
		guard let basket = basket else {return}
		fork = basket.fork + 1
		basket.dirtyAnchor(self)
	}
	override public func delete()  {
		super.delete()
		
		guard let basket = basket else {return}
		basket.deleteAnchor(self)
	}
	
	override func dirty() {
		super.dirty()
		
		guard let basket = basket else {return}
		basket.dirtyAnchor(self)
	}
	
// Anchor ==========================================================================================
	open var isUploaded: Bool {
		return true
	}
	
// Domain ==========================================================================================
	override public var anchor: Anchor {
		get {return self}
	}
	override open var properties: [String] {
		return super.properties + ["fork", "vers"]
	}
}
