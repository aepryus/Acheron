//
//  AEViewController.swift
//  Acheron
//
//  Created by Joe Charlier on 4/28/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import UIKit

open class AEViewController: UIViewController {
	// 0.67
	open func layout320x480() {
		layout375x667()
	}

	// 0.56
	open func layout320x568() {
		layout375x667()
	}
	open func layout375x667() {}
	open func layout414x736() {
		layout375x667()
	}

	// 0.46
	open func layout375x812() {
		layout375x667()
	}
	open func layout414x896() {
		layout375x812()
	}
	
	// 1.33
	open func layout1024x768() {}
	open func layout1112x834() {
		layout1024x768()
	}
	open func layout1366x1024() {
		layout1024x768()
	}
	
	// 1.43
	open func layout1194x834() {
		layout1024x768()
	}

	func layout() {
		switch Screen.this {
			case .dim320x480:	layout320x480()
			case .dim320x568:	layout320x568()
			case .dim375x667:	layout375x667()
			case .dim414x736:	layout414x736()
			case .dim375x812:	layout375x812()
			case .dim414x896:	layout414x896()
			case .dim1024x768:	layout1024x768()
			case .dim1112x834:	layout1112x834()
			case .dim1366x1024:	layout1366x1024()
			case .dim1194x834:	layout1194x834()
			case .dimOther:		layout375x667()
		}
	}
	
// UIViewController ================================================================================
	override open func viewSafeAreaInsetsDidChange() {
		guard #available(iOS 11.0, *) else {return}
		super.viewSafeAreaInsetsDidChange()
		layout()
	}
	override open func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		layout()
	}
}
