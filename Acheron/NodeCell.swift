//
//  NodeCell.swift
//  Acheron
//
//  Created by Joe Charlier on 6/10/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import Foundation

public class NodeCell: UITableViewCell {
	public var node: Node! {
		didSet {
			for i in 0..<nodeView.columns.count {
				let value = node.value(for: nodeView.columns[i].token)
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
		
		let gesture = UITapGestureRecognizer(target: self, action: #selector(onTap))
		addGestureRecognizer(gesture)
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
	
// Events ==========================================================================================
	@objc func onTap() {
		guard let delegate = nodeView.delegate else {return}
		delegate.nodeView(nodeView, didTapNode: node)
	}
	
// UIView ==========================================================================================
	override public func layoutSubviews() {
		var dx: CGFloat = 6*s
		var i: Int = 0
		views.forEach {
			if $0.width != 0 {
				$0.left(dx: dx)
			} else {
				$0.left(dx: dx, width: nodeView.columns[i].width, height: 24*s)
			}
			dx += $0.width
			i += 1
		}
		lineView.bottom(width: width, height: 1*s)
	}
}
