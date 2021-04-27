//
//  ExpandableTableView.swift
//  Acheron
//
//  Created by Joe Charlier on 3/13/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import UIKit

public protocol ExpandableTableViewDelegate: AnyObject {
	func numberOfSections(in tableView: ExpandableTableView) -> Int
	func expandableTableView(_ tableView: ExpandableTableView, heightForHeaderInSection section: Int) -> CGFloat
	func expandableTableView(_ tableView: ExpandableTableView, viewForHeaderInSection section: Int) -> UIView?
	func expandableTableView(_ tableView: ExpandableTableView, numberOfRowsInSection section: Int) -> Int
	func expandableTableView(_ tableView: ExpandableTableView, cellForRowAt indexPath: IndexPath) -> ExpandableCell
	func expandableTableView(_ tableView: ExpandableTableView, expansionForRowAt indexPath: IndexPath) -> UIView
	func expandableTableView(_ tableView: ExpandableTableView, baseHeightForRowAt indexPath: IndexPath) -> CGFloat
	func expandableTableView(_ tableView: ExpandableTableView, expansionHeightForRowAt indexPath: IndexPath) -> CGFloat
	func expandableTableView(_ tableView: ExpandableTableView, expandableRowAt indexPath: IndexPath) -> Bool
	func expandableTableView(_ tableView: ExpandableTableView, reload expansion: UIView, at indexPath: IndexPath)
}
public extension ExpandableTableViewDelegate {
	func numberOfSections(in tableView: ExpandableTableView) -> Int {
		return 1
	}
	func expandableTableView(_ tableView: ExpandableTableView, heightForHeaderInSection section: Int) -> CGFloat {
		return 0
	}
	func expandableTableView(_ tableView: ExpandableTableView, viewForHeaderInSection section: Int) -> UIView? {
		return nil
	}
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
	func expandableTableView(_ tableView: ExpandableTableView, reload expansion: UIView, at indexPath: IndexPath) {}
}

public class ExpandableTableView: AETableView, UITableViewDelegate, UITableViewDataSource {
	public var baseHeight: CGFloat = 60
	public var expansionHeight: CGFloat = 60
	public unowned var expandableTableViewDelegate: ExpandableTableViewDelegate
	public var expandedPath: IndexPath? = nil
	public var exposeBottom: Bool = true
	
	private var currentExpandedView: UIView? = nil
	private var expandedViews: [UIView] = []
	
	public init(delegate: ExpandableTableViewDelegate) {
		expandableTableViewDelegate = delegate
		super.init()
		backgroundColor = UIColor.clear
		self.delegate = self
		dataSource = self
		showsVerticalScrollIndicator = false
	}
	public required init?(coder aDecoder: NSCoder) {fatalError()}
	
	func toggle(cell: ExpandableCell) {
		guard let indexPath = self.indexPath(for: cell) else {return}
		guard expandableTableViewDelegate.expandableTableView(self, expandableRowAt: indexPath) else {return}
		
		var nextExpandedView: UIView? = nil
		
		if indexPath == expandedPath {
			cell.onWillCollapse()
			expandedPath = nil
		} else {
			if let expandedPath = expandedPath, let oldCell = cellForRow(at: expandedPath) as? ExpandableCell {
				oldCell.onWillCollapse()
			}
			cell.onWillExpand()
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
			if self.expandedPath != nil && self.exposeBottom {self.scrollRectToVisible(cell.frame, animated: true)}
			guard let closingExpandedView = closingExpandedView else {return}
			closingExpandedView.removeFromSuperview()
			self.expandedViews.append(closingExpandedView)
		}
		endUpdates()
	}
	public func collapse() {
		guard let expandedPath = expandedPath else {return}
		guard let cell = cellForRow(at: expandedPath) as? ExpandableCell else {return}
		toggle(cell: cell)
	}
	public func collapseSilent() {
		expandedPath = nil
		currentExpandedView = nil
		reloadData()
		layoutIfNeeded()
	}
	
	public func dequeueExpansionView() -> UIView? {
		guard expandedViews.count > 0 else {return nil}
		return expandedViews.removeLast()
	}
	
// UITableViewDelegate =============================================================================
	public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		var height: CGFloat = expandableTableViewDelegate.expandableTableView(tableView as! ExpandableTableView, baseHeightForRowAt:indexPath)
		
		if let expandedPath = expandedPath, expandedPath == indexPath {
			height += expandableTableViewDelegate.expandableTableView(tableView as! ExpandableTableView, expansionHeightForRowAt:indexPath)
		}
		
		return height
	}
	public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return expandableTableViewDelegate.expandableTableView(tableView as! ExpandableTableView, heightForHeaderInSection: section)
	}
	
// UITableViewDataSource ===========================================================================
	public func numberOfSections(in tableView: UITableView) -> Int {
		return expandableTableViewDelegate.numberOfSections(in: tableView as! ExpandableTableView)
	}
	public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		return expandableTableViewDelegate.expandableTableView(tableView as! ExpandableTableView, viewForHeaderInSection: section)
	}
	public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return expandableTableViewDelegate.expandableTableView(tableView as! ExpandableTableView, numberOfRowsInSection: section)
	}
	public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = expandableTableViewDelegate.expandableTableView(tableView as! ExpandableTableView, cellForRowAt: indexPath)
		cell.expandableTableView = self
		if expandedPath == indexPath, let currentExpandedView = currentExpandedView {
			if currentExpandedView.superview != cell {
				currentExpandedView.removeFromSuperview()
				cell.superAddSubview(currentExpandedView)
			}
			expandableTableViewDelegate.expandableTableView(tableView as! ExpandableTableView, reload: currentExpandedView, at: indexPath)
			let baseHeight = expandableTableViewDelegate.expandableTableView(self, baseHeightForRowAt: indexPath)
			let expansionHeight = expandableTableViewDelegate.expandableTableView(self, expansionHeightForRowAt: indexPath)
			currentExpandedView.frame = CGRect(x: 0, y: baseHeight, width: width, height: expansionHeight)
		}
		return cell
	}
}
