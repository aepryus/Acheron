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
	public var createView: (NodeColumn)->(UIView) = { (column: NodeColumn) in
		let label = UILabel()
		if let pen = column.pen {label.pen = pen}
		return label
	}
	public var loadView: (UIView,Any?)->() = { (view: UIView, value: Any?) in
		let label = view as! UILabel
		label.text = "\(value ?? "")"
	}
	public var pen: Pen?
	
	public init(name: String, pen: Pen? = nil) {
		self.name = name
		self.pen = pen
	}
}
