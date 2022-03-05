//
//  UIButton+Acheron.swift
//  Acheron
//
//  Created by Joe Charlier on 4/29/20.
//  Copyright © 2020 Aepryus Software. All rights reserved.
//

import Foundation

public extension UIButton {
	func setTitlePen(_ pen: Pen, for state: UIControl.State) {
		setTitleColor(pen.color, for: state)
		titleLabel?.pen = pen
	}
}
