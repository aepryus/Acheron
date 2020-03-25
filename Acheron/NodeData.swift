//
//  NodeData.swift
//  Acheron
//
//  Created by Joe Charlier on 6/10/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import Foundation

public protocol NodeData {
	var availableNames: [String] {get}
	func value(for name: String) -> Any?
}

class EmptyNodeData: NodeData {
	var availableNames: [String] {return []}
	func value(for name: String) -> Any? {return nil}
}
class GroupNodeData: NodeData {
	var value: String
	
	init(value: String) {
		self.value = value
	}
	
	var availableNames: [String] {return ["name"]}
	func value(for name: String) -> Any? {
		return value
	}
}

extension Domain: NodeData {
	public var availableNames: [String] {
		return properties
	}
	public func value(for name: String) -> Any? {
		return super.value(forKey: name)
	}
}

extension Dictionary: NodeData where Key == String {
	public var availableNames: [String] {
		return Array(keys)
	}
	public func value(for name: String) -> Any? {
		return self[name]
	}
}
