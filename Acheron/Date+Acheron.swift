//
//  Date+Acheron.swift
//  Acheron
//
//  Created by Joe Charlier on 4/7/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import Foundation

public extension Date {
	
	static var formatters: [String:DateFormatter] = [:]
	func format(_ template: String) -> String {
		var formatter = Date.formatters[template]
		if formatter == nil {
			formatter = DateFormatter()
			formatter!.dateFormat = template
			Date.formatters[template] = formatter
		}
		return formatter!.string(from: self)
	}

	static var now: Date {return Date()}
	
	static var isoFormatter: DateFormatter = {
		var formatter = DateFormatter()
		formatter.locale = Locale(identifier: "en_US_POSIX")
		formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
		return formatter
	}()
	func toISOFormattedString() -> String {
		return Date.isoFormatter.string(from: self)
	}
	static func fromISOFormatted(string: String) -> Date? {
		return Date.isoFormatter.date(from: string)
	}
}
