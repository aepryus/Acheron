//
//  NodeColumn.swift
//  Acheron
//
//  Created by Joe Charlier on 6/10/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import Foundation

public protocol NodeFormatter {
	func format(_ input: Any?) -> String
}
private class DefaultFormatter: NodeFormatter {
	func format(_ input: Any?) -> String {
		return "\(input ?? "")"
	}
}

public class NodeColumn {
	let name: String
	public var pen: Pen?
	public var formatter: NodeFormatter

	private static let defaultFormatter: DefaultFormatter = DefaultFormatter()

	public var createView: (NodeColumn)->(UIView) = { (column: NodeColumn) in
		let label = UILabel()
		if let pen = column.pen {label.pen = pen}
		return label
	}
	public var loadView: (UIView,Any?)->() = { (view: UIView, value: Any?) in
		let label = view as! UILabel
		label.text = "\(value ?? "")"
	}
	
	public init(name: String, pen: Pen? = nil, formatter: NodeFormatter? = nil) {
		self.name = name
		self.pen = pen
		self.formatter = formatter == nil ? NodeColumn.defaultFormatter : formatter!
	}
}
