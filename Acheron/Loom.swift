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
	
	public static func start(namespaces: [String]) {
		Loom.namespaces = namespaces
	}
}
