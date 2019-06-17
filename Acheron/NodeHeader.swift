//
//  NodeHeader.swift
//  Acheron
//
//  Created by Joe Charlier on 6/11/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import Foundation

class NodeHeader: UITableViewCell {
	var node: Node! {
		didSet {
			label.text = node.value(for: "name") as? String
		}
	}
	
	private var label: UILabel = UILabel()
	
	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		
		backgroundColor = UIColor(rgb: 0xCCCCCC)
		
		label.textColor = UIColor(rgb: 0x888888)
		addSubview(label)
	}
	required init?(coder aDecoder: NSCoder) {fatalError()}
	
// UIView ==========================================================================================
	override func layoutSubviews() {
		label.left(dx: 6*s, width: 200*s, height: 24*s)
	}
}
