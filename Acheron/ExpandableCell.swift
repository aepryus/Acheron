//
//  ExpandableCell.swift
//  Acheron
//
//  Created by Joe Charlier on 3/13/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import UIKit

public class ExpandableCell: UITableViewCell {
	weak var expandableTableView: ExpandableTableView!
	private let baseView: UIView = UIView()
	
	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		
		clipsToBounds = true
		
		superAddSubview(baseView)
		
		let gesture = UITapGestureRecognizer(target: self, action: #selector(onTap))
		baseView.addGestureRecognizer(gesture)
	}
	required init?(coder aDecoder: NSCoder) {fatalError()}
	
	var indexPath: IndexPath? {
		return expandableTableView.indexPath(for: self)
	}
	var expanded: Bool {
		return expandableTableView.expandedPath == indexPath
	}
	
	func superAddSubview(_ view: UIView) {
		super.addSubview(view)
	}
	
// Events ==========================================================================================
	@objc func onTap() {
		expandableTableView.toggle(cell: self)
	}
	
// UIView ==========================================================================================
	override public func layoutSubviews() {
		var baseHeight: CGFloat = 0
		if let indexPath = indexPath {
			baseHeight = expandableTableView.expandableTableViewDelegate.expandableTableView(expandableTableView, baseHeightForRowAt: indexPath)
		} else {
			baseHeight = expandableTableView.baseHeight
		}
		baseView.frame = CGRect(x: 0, y: 0, width: width, height: baseHeight)
	}
	override public func addSubview(_ view: UIView) {
		baseView.addSubview(view)
	}
	override public var backgroundColor: UIColor? {
		set {
			baseView.backgroundColor = newValue
			// Apple is doing something weird under the covers here.
			// This is necessary to prevent them switching the color back to white.
			// jjc:3/13/19
			super.backgroundColor = newValue
		}
		get {return baseView.backgroundColor}
	}
}
