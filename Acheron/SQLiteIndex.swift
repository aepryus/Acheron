//
//  SQLiteIndex.swift
//  Acheron
//
//  Created by Joe Charlier on 4/23/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import Foundation

class SQLiteIndex {
	var name: String
	var field: String
	
	init(name: String, field: String) {
		self.name = name
		self.field = field
	}
}
