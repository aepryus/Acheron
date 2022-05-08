//
//  Array+Acheron.swift
//  Acheron
//
//  Created by Joe Charlier on 5/10/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import Foundation

public extension Array where Element: Equatable {
	mutating func remove(object: Element) {
		if let index = firstIndex(of: object) {
			remove(at: index)
		}
	}
}

public extension Array {
	func toJSON() -> String {
		do {
			let data = try JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
			return String(data:data, encoding: .utf8)!
		} catch {
			print("\(error)")
			return ""
		}
	}
}
