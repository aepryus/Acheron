//
//  Date+Acheron.swift
//  Acheron
//
//  Created by Joe Charlier on 4/7/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import Foundation

public extension Date {

	init(_ string: String) {
		let formatter = DateFormatter()
		formatter.dateFormat = "MM/dd/yy"
		formatter.locale = NSLocale(localeIdentifier: "en_US_POSIX") as Locale
		let date = formatter.date(from: string)!
		self.init(timeInterval:0, since:date)
	}

	private static var formatters: [String:DateFormatter] = [:]
	func format(_ template: String) -> String {
		var formatter = Date.formatters[template]
		if formatter == nil {
			formatter = DateFormatter()
			formatter!.dateFormat = template
			Date.formatters[template] = formatter
		}
		return formatter!.string(from: self)
	}

	@available(iOS, obsoleted: 15.0)
	@available(macOS, obsoleted: 12.0)
	@available(macCatalyst, obsoleted: 15.0)
	@available(tvOS, obsoleted: 15.0)
	@available(watchOS, obsoleted: 8.0)
	static var now: Date { Date() }

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
