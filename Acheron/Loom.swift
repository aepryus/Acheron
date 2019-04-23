//
//  Loom.swift
//  Acheron
//
//  Created by Joe Charlier on 4/23/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import Foundation

public class Loom {
	private static var namespaces: [String] = []
	public static var basket: Basket!

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
			if cls != nil {break}
		}
		return cls
	}
	
	public static func set(key: String, value: String) {
		Loom.basket.set(key: key, value: value)
	}
	public static func get(key: String) -> String? {
		return Loom.basket.get(key: key)
	}
	public static func create(cls: Anchor.Type) -> Anchor {
		return Loom.basket.createByClass(cls)
	}
	
	public static func selectByID(_ iden: String) -> Anchor? {
		return Loom.basket.selectByID(iden)
	}
	public static func selectOneWhere(field: String, value: String, type: Anchor.Type) -> Domain? {
		return Loom.basket.selectOneWhere(field: field, value: value, type: type)
	}
	public static func selectWhere(field: String, value: String, type: Anchor.Type) -> [Domain] {
		return Loom.basket.selectWhere(field: field, value: value, type: type)
	}
	public static func selectAll(_ type: Anchor.Type) -> [Anchor] {
		return Loom.basket.selectAll(type)
	}
	
	public static func transact(_ closure: ()->()) {
		Loom.basket.transact(closure)
	}
	
	public static func start(basket: Basket, namespaces: [String]) {
		Loom.basket = basket
		Loom.namespaces = namespaces
	}
}
