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

public extension Collection {
	func toJSON() -> String {
		do {
			let data = try JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
			return String(data:data, encoding: .utf8)!
		} catch {
			print("\(error)")
			return ""
		}
	}
	func summate(_ value: (Element)->(Int)) -> Int {
		var sum: Int = 0
		forEach { sum += value($0) }
		return sum
	}
	func maximum(_ value: (Element)->(Int)) -> Int? {
		var maximum: Int? = nil
		forEach {
			let v = value($0)
			if maximum == nil || v > maximum! { maximum = v }
		}
		return maximum
	}
}
