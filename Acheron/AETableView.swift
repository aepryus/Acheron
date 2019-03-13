//
//  AETableView.swift
//  Acheron
//
//  Created by Joe Charlier on 3/13/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import UIKit

class AETableView: UITableView {
	init() {
		super.init(frame: CGRect.zero, style: .plain)
		
		separatorStyle = .none
		tableFooterView = nil
		allowsSelection = false
	}
	required init?(coder aDecoder: NSCoder) {fatalError()}
}
