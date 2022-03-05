//
//  NodeHeader.swift
//  Acheron
//
//  Created by Joe Charlier on 6/11/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

#if canImport(UIKit)

import UIKit

class NodeHeader: UITableViewCell {
	var node: Node! {
		didSet {
			label.text = node.value(for: "name") as? String
			for i in 0..<nodeView.columns.count {
				labels[i].text = nodeView.columns[i].title
			}
		}
	}
	unowned var nodeView: NodeView!
	
	private var label: UILabel = UILabel()
	private var labels: [UILabel] = []
	
	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		
		backgroundColor = UIColor(rgb: 0xE7E7E7)
		
		label.font = UIFont(name: "HelveticaNeue", size: 16*s)
		label.textColor = UIColor(rgb: 0x333333)
		addSubview(label)
	}
	required init?(coder aDecoder: NSCoder) {fatalError()}
	
	func renderFields() {
		labels.forEach {$0.removeFromSuperview()}
		labels.removeAll()
		for column in nodeView.columns {
			let label = UILabel()
			label.font = UIFont(name: "HelveticaNeue", size: 14*s)
			label.textAlignment = column.alignment
			label.textColor = UIColor(rgb: 0x666666)
			addSubview(label)
			labels.append(label)
		}
	}
	
// UIView ==========================================================================================
	override func layoutSubviews() {
		label.left(dx: 6*s, width: 200*s, height: 24*s)
		var dx: CGFloat = 6*s
		var i: Int = 0
		labels.forEach {
			$0.left(dx: dx, width: nodeView.columns[i].width, height: 24*s)
			dx += $0.width
			i += 1
		}
	}
}

#endif
