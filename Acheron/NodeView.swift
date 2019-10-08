//
//  NodeView.swift
//  Acheron
//
//  Created by Joe Charlier on 6/10/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import Foundation

public protocol NodeViewDelegate: class {
	func nodeView(_ nodeView: NodeView, didTapNode node: Node)
}
public extension NodeViewDelegate {
	func nodeView(_ nodeView: NodeView, didTapNode node: Node) {}
}

public class NodeView: UIView, UITableViewDataSource {
	public var node: Node! {
		didSet{tableView.reloadData()}
	}
	
	public var columns: [NodeColumn] = []
	
	let tableView: UITableView = AETableView()
	public weak var delegate: NodeViewDelegate? = nil
	
	public var forEachCell: (NodeCell)->() = {NodeCell in}
	
	public init() {
		super.init(frame: CGRect.zero)
		
		backgroundColor = UIColor(rgb: 0xFFFFFF)
		
		tableView.register(NodeCell.self, forCellReuseIdentifier: "cell")
		tableView.register(NodeHeader.self, forCellReuseIdentifier: "header")
		tableView.backgroundColor = UIColor.clear
		tableView.dataSource = self
		addSubview(tableView)
	}
	required init?(coder aDecoder: NSCoder) {fatalError()}
	
	public var rowHeight: CGFloat {
		set {tableView.rowHeight = newValue}
		get {return tableView.rowHeight}
	}
	
// UIView ==========================================================================================
	public override func layoutSubviews() {
		tableView.frame = bounds
	}
	
// UITableViewDataSource ===========================================================================
	public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return node.deepChildCount()
	}
	public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let current: Node = node.deepChild(at: indexPath.row)
		if current.children.count != 0 {
			let cell = tableView.dequeueReusableCell(withIdentifier: "header") as! NodeHeader
			cell.nodeView = self
			cell.renderFields()
			cell.node = node.deepChild(at: indexPath.row)
			return cell
		} else {
			let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! NodeCell
			cell.nodeView = self
			cell.renderFields()
			cell.node = node.deepChild(at: indexPath.row)
			forEachCell(cell)
			return cell
		}
	}
}
