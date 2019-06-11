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
	private var lineView: UIView = UIView()
	
	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		
		addSubview(label)
		
		lineView.backgroundColor = UIColor(rgb: 0xAAAAAA)
		addSubview(lineView)
	}
	required init?(coder aDecoder: NSCoder) {fatalError()}
	
// UIView ==========================================================================================
	override func layoutSubviews() {
		label.left(dx: 6*s, width: 200*s, height: 24*s)
		lineView.bottom(width: width, height: 1*s)
	}
}
