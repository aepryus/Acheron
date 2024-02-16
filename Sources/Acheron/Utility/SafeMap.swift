//
//  SafeMap.swift
//  Acheron
//
//  Created by Joe Charlier on 8/24/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import Foundation

public class SafeMap<T> {
    private var map: [String:T] = [:]
    private let queue: DispatchQueue = DispatchQueue(label: "SafeMap")
    
    public init() {}
    
    public subscript(key: String) -> T? {
        set { queue.sync { map[key] = newValue } }
        get { queue.sync { map[key] } }
    }

    public var values: [T] { queue.sync { Array(map.values) } }
    public var count: Int { queue.sync { map.count } }

    @discardableResult
    public func removeValue(forKey key: String) -> T? {
        var result: T? = nil
        queue.sync { result = map.removeValue(forKey: key) }
        return result
    }
    public func removeAll() { queue.sync { map.removeAll() } }
}
