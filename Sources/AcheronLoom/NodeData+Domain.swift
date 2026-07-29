//
//  NodeData+Domain.swift
//  Acheron
//
//  Created by Joe Charlier on 7/29/26.
//  Copyright © 2026 Aepryus Software. All rights reserved.
//

#if canImport(UIKit)

import Acheron

extension Domain: NodeData {
    public var availableNames: [String] { properties }
    public func value(for name: String) -> Any? { loomGet(name) }
}

#endif
