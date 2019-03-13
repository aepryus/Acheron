//
//  ExpandableTableView.swift
//  Acheron
//
//  Created by Joe Charlier on 3/13/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import UIKit

protocol ExpandableTableViewDelegate: class {
	func expandableTableView(_ tableView: ExpandableTableView, numberOfRowsInSection section: Int) -> Int
	func expandableTableView(_ tableView: ExpandableTableView, cellForRowAt indexPath: IndexPath) -> ExpandableCell
	func expandableTableView(_ tableView: ExpandableTableView, expansionForRowAt indexPath: IndexPath) -> UIView
	func expandableTableView(_ tableView: ExpandableTableView, baseHeightForRowAt indexPath: IndexPath) -> CGFloat
	func expandableTableView(_ tableView: ExpandableTableView, expansionHeightForRowAt indexPath: IndexPath) -> CGFloat
	func expandableTableView(_ tableView: ExpandableTableView, expandableRowAt indexPath: IndexPath) -> Bool
}
extension ExpandableTableViewDelegate {
	func expandableTableView(_ tableView: ExpandableTableView, expansionForRowAt indexPath: IndexPath) -> UIView {
		let view = UIView()
		view.backgroundColor = UIColor.blue.tint(0.5)
		return view
	}
	func expandableTableView(_ tableView: ExpandableTableView, baseHeightForRowAt indexPath: IndexPath) -> CGFloat {
		return tableView.baseHeight
	}
	func expandableTableView(_ tableView: ExpandableTableView, expansionHeightForRowAt indexPath: IndexPath) -> CGFloat {
		return tableView.expansionHeight
	}
	func expandableTableView(_ tableView: ExpandableTableView, expandableRowAt indexPath: IndexPath) -> Bool {
		return true
	}
}

class ExpandableTableView: AETableView, UITableViewDelegate, UITableViewDataSource {
	var baseHeight: CGFloat = 60
	var expansionHeight: CGFloat = 60
	unowned var expandableTableViewDelegate: ExpandableTableViewDelegate
	var expandedPath: IndexPath? = nil
	
	var currentExpandedView: UIView? = nil
	var expandedViews: [UIView] = []
	
	init(delegate: ExpandableTableViewDelegate) {
		expandableTableViewDelegate = delegate
		super.init()
		backgroundColor = UIColor.clear
		self.delegate = self
		dataSource = self
	}
	required init?(coder aDecoder: NSCoder) {fatalError()}
	
	func toggle(cell: ExpandableCell) {
		guard let indexPath = self.indexPath(for: cell) else {fatalError()}
		guard expandableTableViewDelegate.expandableTableView(self, expandableRowAt: indexPath) else {return}
		
		var nextExpandedView: UIView? = nil
		
		if indexPath == expandedPath {
			expandedPath = nil
		} else {
			expandedPath = indexPath
			nextExpandedView = expandableTableViewDelegate.expandableTableView(self, expansionForRowAt: indexPath)
			cell.superAddSubview(nextExpandedView!)
			let baseHeight = expandableTableViewDelegate.expandableTableView(self, baseHeightForRowAt: indexPath)
			let expansionHeight = expandableTableViewDelegate.expandableTableView(self, expansionHeightForRowAt: indexPath)
			nextExpandedView!.frame = CGRect(x: 0, y: baseHeight, width: width, height: expansionHeight)
		}
		
		let closingExpandedView = currentExpandedView
		currentExpandedView = nextExpandedView
		
		beginUpdates()
		CATransaction.setCompletionBlock {
			guard let closingExpandedView = closingExpandedView else {return}
			closingExpandedView.removeFromSuperview()
			self.expandedViews.append(closingExpandedView)
		}
		endUpdates()
	}
	
	// UITableViewDelegate =============================================================================
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		var height: CGFloat = expandableTableViewDelegate.expandableTableView(tableView as! ExpandableTableView, baseHeightForRowAt:indexPath)
		
		if let expandedPath = expandedPath, expandedPath == indexPath {
			height += expandableTableViewDelegate.expandableTableView(tableView as! ExpandableTableView, expansionHeightForRowAt:indexPath)
		}
		
		return height
	}
	
	// UITableViewDataSource ===========================================================================
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return expandableTableViewDelegate.expandableTableView(tableView as! ExpandableTableView, numberOfRowsInSection: section)
	}
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = expandableTableViewDelegate.expandableTableView(tableView as! ExpandableTableView, cellForRowAt: indexPath)
		cell.expandableTableView = self
		return cell
	}
}
