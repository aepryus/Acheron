//
//  NodeColumn.swift
//  Acheron
//
//  Created by Joe Charlier on 6/10/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import Foundation

public class NodeColumn {
	let name: String
	public var pen: Pen?
	public var format: (Any?)->(String)
	
	static let defaultFormat: (Any?)->(String) = { (input: Any?)->(String) in
		return "\(input ?? "")"
	}
	
	public var createView: (NodeColumn)->(UIView) = { (column: NodeColumn) in
		let label = UILabel()
		if let pen = column.pen {label.pen = pen}
		return label
	}
	public var loadView: (NodeColumn,UIView,Any?)->() = { (column: NodeColumn, view: UIView, value: Any?) in
		let label = view as! UILabel
		label.text = column.format(value)
	}
	
	public init(name: String, pen: Pen? = nil, format: ((Any?)->(String))? = nil) {
		self.name = name
		self.pen = pen
		self.format = format != nil ? format! : NodeColumn.defaultFormat
	}
}
