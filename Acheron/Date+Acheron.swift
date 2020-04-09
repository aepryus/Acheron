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
	static var iso8601Formatter: ISO8601DateFormatter = {
		let formatter: ISO8601DateFormatter = ISO8601DateFormatter()
		if #available(iOS 11, *) {
			formatter.formatOptions = [.withFractionalSeconds, .withInternetDateTime]
		}
		return formatter
	}()
	func toISOFormattedString() -> String {
		return Date.isoFormatter.string(from: self)
	}
	static func fromISOFormatted(string: String) -> Date? {
		return Date.iso8601Formatter.date(from: string) ?? Date.isoFormatter.date(from: string)
	}
}
