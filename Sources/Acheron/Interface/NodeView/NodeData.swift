//
//  NodeData.swift
//  Acheron
//
//  Created by Joe Charlier on 6/10/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

#if canImport(UIKit)

import Foundation

public protocol NodeData {
    var availableNames: [String] { get }
    func value(for name: String) -> Any?
}

class EmptyNodeData: NodeData {
    var availableNames: [String] { [] }
    func value(for name: String) -> Any? { nil }
}
class GroupNodeData: NodeData {
    var value: String
    
    init(value: String) {
        self.value = value
    }
    
    var availableNames: [String] { ["name"] }
    func value(for name: String) -> Any? { value }
}

extension Domain: NodeData {
    public var availableNames: [String] { properties }
    public func value(for name: String) -> Any? { super.value(forKey: name) }
}

extension Dictionary: NodeData where Key == String {
    public var availableNames: [String] { Array(keys) }
    public func value(for name: String) -> Any? { self[name] }
}

#endif
