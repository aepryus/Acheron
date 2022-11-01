//
//  Codable+Acheron.swift
//  
//
//  Created by Joe Charlier on 5/8/22.
//  Copyright © 2022 Aepryus Software. All rights reserved.
//

import Foundation

extension Decodable {
    public init?(json: String) {
        guard let data = json.data(using: .utf8) else { return nil }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        do {
            self = try decoder.decode(Self.self, from: data)
        } catch {
            print("ERROR: Decodable.init?(json: String) [\(error)]")
            return nil
        }
    }
}
extension Encodable {
    public func toJSON() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        let data = try! encoder.encode(self)
        return String(data: data, encoding: .utf8)!
    }
}
