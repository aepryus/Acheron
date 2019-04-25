//
//  Loom.swift
//  Acheron
//
//  Created by Joe Charlier on 4/23/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import Foundation

public class Loom {
	public static var basket: Basket!

	private static var namespaces: [String] = []
	static var domains = [String:[String:AnyClass]]()

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
	
	static func classForKeyPath(keyPath: String, parent: Domain.Type) -> AnyClass? {
		var n: UInt32 = 0
		let properties: UnsafeMutablePointer<objc_property_t>? = class_copyPropertyList(parent, &n)
		var cls: AnyClass?
		
		for i in 0..<Int(n) {
			let name = String(validatingUTF8: property_getName(properties![i]))
			if keyPath != name {continue}
			
			let attributes: UnsafePointer<Int8> = property_getAttributes(properties![i])!
			if attributes[1] == Int8(UInt8(ascii:"@")) {
				var className: String = String()
				var j = 3
				while attributes[j] != 0 && attributes[j] != Int8(UInt8(ascii:"\"")) {
					className.append(Character(UnicodeScalar(UInt8(attributes[j]))))
					j += 1
				}
				cls = NSClassFromString(className)
			}
			break;
		}
		free(properties)
		
		if cls == nil {
			let superclass: NSObject.Type = class_getSuperclass(parent) as! NSObject.Type
			if superclass != NSObject.self {
				cls = classForKeyPath(keyPath: keyPath, parent: superclass as! Domain.Type)
			}
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
	public static func selectOne(where field: String, is value: String, type: Anchor.Type) -> Domain? {
		return Loom.basket.selectOne(where: field, is: value, type: type)
	}
	public static func select(where field: String, is value: String, type: Anchor.Type) -> [Domain] {
		return Loom.basket.select(where: field, is: value, type: type)
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
