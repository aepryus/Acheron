//
//  Collection+Acheron.swift
//  Acheron
//
//  Created by Joe Charlier on 1/25/18.
//  Copyright © 2018 Aepryus Software. All rights reserved.
//

import Foundation

public extension Collection where Index == Int {
	func random() -> Iterator.Element? {
		return isEmpty ? nil : self[Int.random(in: 0 ..< endIndex)]
	}
}
