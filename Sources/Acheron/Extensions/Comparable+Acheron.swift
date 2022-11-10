//
//  Comparable+Acheron.swift
//  Acheron
//
//  Created by Joe Charlier on 12/22/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import Foundation

public extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self { min(max(self, limits.lowerBound), limits.upperBound) }
}
