//
//  Dictionary+Acheron.swift
//  Acheron
//
//  Created by Joe Charlier on 4/23/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import Foundation

public extension Dictionary where Key == String {
	func toJSON() -> String {
		do {
			let data = try JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
			return String(data:data, encoding: .utf8)!
		} catch {
			print("\(error)")
			return ""
		}
	}
	func modify(query: [String], convert: (Value)->(Value)) -> Self {
		var result: Self = [:]
		keys.forEach { (key: String) in
			if query.contains(key) { result[key] = convert(self[key]!) }
			else if let subAtts = self[key] as? [String:Value] { result[key] = subAtts.modify(query: query, convert: convert) as? Value }
			else if let subArray = self[key] as? [[String:Value]] {
				var subResult: [[String:Value]] = []
				subArray.forEach { subResult.append($0.modify(query: query, convert: convert)) }
				result[key] = subResult as? Value
			} else {
				result[key] = self[key]
			}
		}
		return result
	}
}
