//
//  Node.swift
//  Acheron
//
//  Created by Joe Charlier on 6/10/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import Foundation

public class Node {
	public var data: NodeData
	var children: [Node] = []
	
	public init(data: NodeData) {
		self.data = data
	}
	public init(datum: [NodeData]) {
		data = EmptyNodeData()
		datum.forEach {children.append(Node(data: $0))}
	}
	
	func deepChildCount() -> Int {
		var count: Int = (data is EmptyNodeData ? 0 : 1)
		children.forEach {count += $0.deepChildCount()}
		return count
	}
	func deepChild(at: Int) -> Node {
		var index: Int = at
		if !(data is EmptyNodeData) {
			if index == 0 {return self}
			index -= 1
		}
		
		for child in children {
			if index < child.deepChildCount() {
				return child.deepChild(at: index)
			} else {
				index -= child.deepChildCount()
			}
		}
		fatalError()
	}
	
	public func value(for name: String) -> Any? {
		return data.value(for: name)
	}
	
	public func sort(by: String) {
		children.sort { (lhs: Node, rhs: Node) -> Bool in
			if let lhs = lhs.value(for: by) as? String, let rhs = rhs.value(for: by) as? String {
				return lhs < rhs
			}
			if let lhs = lhs.value(for: by) as? Double, let rhs = rhs.value(for: by) as? Double {
				return lhs < rhs
			}
			if let lhs = lhs.value(for: by) as? Int, let rhs = rhs.value(for: by) as? Int {
				return lhs < rhs
			}
			fatalError()
		}
	}
	public func node(groupedBy: String, sortedBy: String) -> Node {
		var groups: [String:[Node]] = [:]
		
		children.forEach {
			let group = $0.value(for: groupedBy) as? String ?? "(none)"
			if groups[group] == nil {groups[group] = []}
			groups[group]!.append($0)
		}
		
		let node: Node = Node(data: EmptyNodeData())
		
		for name in groups.keys {
			let groupNode: Node = Node(data: GroupNodeData(value: name))
			groupNode.children = groups[name]!.sorted { (lhs: Node, rhs: Node) -> Bool in
				if let lhs = lhs.value(for: sortedBy) as? String, let rhs = rhs.value(for: sortedBy) as? String {
					return lhs < rhs
				}
				if let lhs = lhs.value(for: sortedBy) as? Double, let rhs = rhs.value(for: sortedBy) as? Double {
					return lhs < rhs
				}
				fatalError()
			}
			node.children.append(groupNode)
		}
		node.children.sort { (lhs: Node, rhs: Node) -> Bool in
			if let lhs = lhs.value(for: "name") as? String, let rhs = rhs.value(for: "name") as? String {
				return lhs < rhs
			}
			fatalError()
		}
		
		return node
	}
}
