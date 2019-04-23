//
//  Dictionary+Acheron.swift
//  Acheron
//
//  Created by Joe Charlier on 4/23/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import Foundation

extension Dictionary where Key == String {
	public func toJSON() -> String {
		do {
			let data = try JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
			return String(data:data, encoding: .utf8)!
		} catch {
			print("\(error)")
			return ""
		}
	}
}
