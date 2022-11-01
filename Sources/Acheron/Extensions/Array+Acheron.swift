//
//  Array+Acheron.swift
//  Acheron
//
//  Created by Joe Charlier on 5/10/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import Foundation

public extension Array where Element: Equatable {
    mutating func remove(object: Element) {
        if let index = firstIndex(of: object) {
            remove(at: index)
        }
    }
}

public extension Collection {
    func toJSON() -> String {
        do {
            let data = try JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
            return String(data:data, encoding: .utf8)!
        } catch {
            print("\(error)")
            return ""
        }
    }
    func summate<T: BinaryInteger>(_ value: (Element)->(T)) -> T {
        var sum: T = 0
        forEach { sum += value($0) }
        return sum
    }
    func summate<T: FloatingPoint>(_ value: (Element)->(T)) -> T {
        var sum: T = 0
        forEach { sum += value($0) }
        return sum
    }
    func maximum<T: BinaryInteger>(_ value: (Element)->(T)) -> T? {
        var maximum: T? = nil
        forEach {
            let v = value($0)
            if maximum == nil || v > maximum! { maximum = v }
        }
        return maximum
    }
    func max<T: BinaryFloatingPoint>(_ value: (Element)->(T)) -> T {
        var max: T? = nil
        forEach {
            let v = value($0)
            if max == nil || v > max! { max = v }
        }
        return max!
    }
    func min<T: BinaryFloatingPoint>(_ value: (Element)->(T)) -> T {
        var min: T? = nil
        forEach {
            let v = value($0)
            if min == nil || v < min! { min = v }
        }
        return min!
    }
}
