//
//  UILabel+Acheron.swift
//  Acheron
//
//  Created by Joe Charlier on 4/16/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import UIKit

public extension UILabel {
	var pen: Pen {
		set {
			font = newValue.font
			textColor = newValue.color
			textAlignment = newValue.alignment
		}
		get { fatalError() }
	}
}
