//
//  CaseIterable+Acheron.swift
//  Acheron
//
//  Created by Joe Charlier on 10/15/20.
//  Copyright © 2020 Aepryus Software. All rights reserved.
//

import Foundation

public extension CaseIterable {
    static func from(string: String) -> Self? { Self.allCases.first { string == "\($0)" } }
    func toString() -> String { "\(self)" }
}
