//
//  SafeMap.swift
//  Acheron
//
//  Created by Joe Charlier on 8/24/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import Foundation

class SafeMap<T> {
	private var map: [String:T] = [:]
	private let queue: DispatchQueue = DispatchQueue(label: "SafeMap")
	
	subscript(key: String) -> T? {
		set {
			queue.sync { map[key] = newValue }
		}
		get {
			var result: T? = nil
			queue.sync { result = map[key] }
			return result
		}
	}
	
	@discardableResult
	func removeValue(forKey key: String) -> T? {
		var result: T? = nil
		queue.sync { result = map.removeValue(forKey: key) }
		return result
	}
	func removeAll() {
		queue.sync { map.removeAll() }
	}
}
