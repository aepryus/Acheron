//
//  Rosetta.swift
//  Acheron
//
//  Created by Joe Charlier on 8/24/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import Foundation

class Rosetta {
	private var map: [String:String] = [:]
	private let queue: DispatchQueue = DispatchQueue(label: "Rosetta")
	
	subscript(key: String) -> String? {
		set {
			queue.sync {
				map[key] = newValue
			}
		}
		get {
			var result: String? = nil
			queue.sync {
				result = map[key]
			}
			return result
		}
	}
}
