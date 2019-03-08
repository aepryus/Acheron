//
//  UIViewController+Acheron.swift
//  Acheron
//
//  Created by Joe Charlier on 3/8/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import UIKit

public extension UIViewController {
	public var s: CGFloat {
		return Screen.s
	}
	
	func layout320x568() {
		layout375x667()
	}
	func layout375x667() {}
	func layout414x736() {
		layout320x568()
	}
	func layout1024x768() {}
	func layout1112x834() {
		layout1024x768()
	}
	func layout1366x1024() {
		layout1024x768()
	}
	func layout() {
		switch Screen.this {
			case .dim320x568:	layout320x568()
			case .dim375x667:	layout375x667()
			case .dim414x736:	layout414x736()
			case .dim1024x768:	layout1024x768()
			case .dim1112x834:	layout1112x834()
			case .dim1366x1024:	layout1366x1024()
			default:			layout375x667()
		}
	}
	
}
