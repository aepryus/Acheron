//
//  Codable+Acheron.swift
//  
//
//  Created by Joe Charlier on 5/8/22.
//  Copyright © 2022 Aepryus Software. All rights reserved.
//

import Foundation

extension Decodable {
	init?(json: String) throws {
		guard let data = json.data(using: .utf8) else { return nil }
		let decoder = JSONDecoder()
		decoder.keyDecodingStrategy = .convertFromSnakeCase
		decoder.dateDecodingStrategy = .iso8601
		self = try decoder.decode(Self.self, from: data)
	}
}
extension Encodable {
	func toJSON() -> String {
		let encoder = JSONEncoder()
		encoder.outputFormatting = .prettyPrinted
		let data = try! encoder.encode(self)
		return String(data: data, encoding: .utf8)!
	}
}
