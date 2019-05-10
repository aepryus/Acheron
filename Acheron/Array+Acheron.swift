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
