//
//  AETableView.swift
//  Acheron
//
//  Created by Joe Charlier on 3/13/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import UIKit

public class AETableView: UITableView {
	public init() {
		super.init(frame: CGRect.zero, style: .plain)
		
		separatorStyle = .none
		tableFooterView = nil
		allowsSelection = false
	}
	required init?(coder aDecoder: NSCoder) {fatalError()}
}
