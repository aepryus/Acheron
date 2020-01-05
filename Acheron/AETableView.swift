//
//  AETableView.swift
//  Acheron
//
//  Created by Joe Charlier on 3/13/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import UIKit

open class AETableView: UITableView {
	public init() {
		super.init(frame: CGRect.zero, style: .plain)
		
		separatorStyle = .none
		tableFooterView = nil
		allowsSelection = false
	}
	required public init?(coder aDecoder: NSCoder) {fatalError()}
	
// UITableView =====================================================================================
	override public var refreshControl: UIRefreshControl? {
		didSet {
			guard let refreshControl = refreshControl else {return}
			refreshControl.layer.zPosition = -1
		}
	}
}
