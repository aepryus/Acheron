//
//  NodeCell.swift
//  Acheron
//
//  Created by Joe Charlier on 6/10/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import Foundation

class NodeCell: UITableViewCell {
	var node: Node! {
		didSet {
			for i in 0..<nodeView.columns.count {
				let name = nodeView.columns[i].name
				let value = node.value(for: name)
				nodeView.columns[i].loadView(nodeView.columns[i],views[i],value)
			}
		}
	}
	unowned var nodeView: NodeView!
	
	private var views: [UIView] = []
	private var lineView: UIView = UIView()
	
	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		
		lineView.backgroundColor = UIColor(rgb: 0xCCCCCC)
		addSubview(lineView)
	}
	required init?(coder aDecoder: NSCoder) {fatalError()}
	
	func renderFields() {
		views.forEach {$0.removeFromSuperview()}
		views.removeAll()
		for column in nodeView.columns {
			let view = column.createView(column)
			addSubview(view)
			views.append(view)
		}
	}
	
// UIView ==========================================================================================
	override func layoutSubviews() {
		var dx: CGFloat = 6*s
		views.forEach {
			if $0.width != 0 {
				$0.left(dx: dx)
			} else {
				$0.left(dx: dx, width: 60*s, height: 24*s)
			}
			dx += $0.width+6*s
		}
		lineView.bottom(width: width, height: 1*s)
	}
}
