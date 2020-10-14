//
//  UIView+Acheron.swift
//  Acheron
//
//  Created by Joe Charlier on 3/8/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import UIKit

public enum Screen {
	case dim320x480, dim320x568, dim375x667, dim414x736, dim375x812, dim390x844, dim414x896, dim1024x768, dim1080x810, dim1112x834, dim1194x834, dim1366x1024, dimOther
	
	public static var keyWindow: UIWindow? {
		if #available(iOS 13.0, *) {
			return UIApplication.shared.windows.first { $0.isKeyWindow }
		} else {
			return UIApplication.shared.keyWindow
		}
	}

// Static ==========================================================================================
	public static var this: Screen {
		let size = UIScreen.main.bounds.size
		
		for (w, h) in [(size.width, size.height), (size.height, size.width)] {
			if w == 320 && h == 480 { return .dim320x480 }		// 0.67
			
			if w == 320 && h == 568 { return .dim320x568 }		// 0.56
			if w == 375 && h == 667 { return .dim375x667 }
			if w == 414 && h == 736 { return .dim414x736 }
			
			if w == 375 && h == 812 { return .dim375x812 }		// 0.46
			if w == 390 && h == 844 { return .dim390x844 }
			if w == 414 && h == 896 { return .dim414x896 }
			
			if w == 1024 && h == 768 { return .dim1024x768 }	// 1.33
			if w == 1080 && h == 810 { return .dim1080x810 }
			if w == 1112 && h == 834 { return .dim1112x834 }
			if w == 1366 && h == 1024 { return .dim1366x1024 }
			
			if w == 1194 && h == 834 { return .dim1194x834 }	// 1.43
		}
		
		print("unknown device: (width: \(size.width), height: \(size.height)")
		
		return .dimOther
	}
	public static var iPhone: Bool {
		return Screen.this == .dim320x480
			|| Screen.this == .dim320x568
			|| Screen.this == .dim375x667
			|| Screen.this == .dim414x736
			|| Screen.this == .dim375x812
			|| Screen.this == .dim414x896
	}
	public static var iPad: Bool {
		return !iPhone
	}
	
	public static var bounds: CGRect {
		return UIScreen.main.bounds
	}
	public static var width: CGFloat {
		return UIScreen.main.bounds.size.width
	}
	public static var height: CGFloat {
		return UIScreen.main.bounds.size.height
	}
	public static var safeTop: CGFloat {
		guard let window = Screen.keyWindow else { fatalError() }
		return window.safeAreaInsets.top
	}
	public static var navBottom: CGFloat {
		return Screen.safeTop + 44
	}
	public static var safeBottom: CGFloat {
		guard #available(iOS 11.0, *), let window = Screen.keyWindow else { return 0 }
		return window.safeAreaInsets.bottom
	}
	public static var safeLeft: CGFloat {
		guard #available(iOS 11.0, *), let window = Screen.keyWindow else { return 0 }
		return window.safeAreaInsets.left
	}
	public static var safeRight: CGFloat {
		guard #available(iOS 11.0, *), let window = Screen.keyWindow else { return 0 }
		return window.safeAreaInsets.right
	}
	public static var s: CGFloat {
		if Screen.iPhone {
			return Screen.width / 375
		} else {
			return min(Screen.height,Screen.width) / 768
		}
	}
}

public extension UIView {
	
	var s: CGFloat {
		return Screen.s
	}
	
	private var parent: CGSize {
		if let parent = superview {
			return parent.bounds.size
		} else {
			return UIScreen.main.bounds.size
		}
	}
	
	func center(dx: CGFloat = 0, dy: CGFloat = 0, width: CGFloat = -1, height: CGFloat = -1) {
		let width = width == -1 ? self.width : width; let height = height == -1 ? self.height : height
		frame = CGRect(x: (parent.width-width)/2+dx, y: (parent.height-height)/2+dy, width: width, height: height)
	}
	func right(dx: CGFloat = 0, dy: CGFloat = 0, width: CGFloat = -1, height: CGFloat = -1) {
		let width = width == -1 ? self.width : width; let height = height == -1 ? self.height : height
		self.frame = CGRect(x: parent.width-width+dx, y: (parent.height-height)/2+dy, width: width, height: height)
	}
	func left(dx: CGFloat = 0, dy: CGFloat = 0, width: CGFloat = -1, height: CGFloat = -1) {
		let width = width == -1 ? self.width : width; let height = height == -1 ? self.height : height
		self.frame = CGRect(x: dx, y: (parent.height-height)/2+dy, width: width, height: height)
	}
	func top(dx: CGFloat = 0, dy: CGFloat = 0, width: CGFloat = -1, height: CGFloat = -1) {
		let width = width == -1 ? self.width : width; let height = height == -1 ? self.height : height
		self.frame = CGRect(x: (parent.width-width)/2+dx, y: dy, width: width, height: height)
	}
	func bottom(dx: CGFloat = 0, dy: CGFloat = 0, width: CGFloat = -1, height: CGFloat = -1) {
		let width = width == -1 ? self.width : width; let height = height == -1 ? self.height : height
		self.frame = CGRect(x: (parent.width-width)/2+dx, y: parent.height-height+dy, width: width, height: height)
	}
	func topLeft(dx: CGFloat = 0, dy: CGFloat = 0, width: CGFloat = -1, height: CGFloat = -1) {
		let width = width == -1 ? self.width : width; let height = height == -1 ? self.height : height
		self.frame = CGRect(x: dx, y: dy, width: width, height: height)
	}
	func topRight(dx: CGFloat = 0, dy: CGFloat = 0, width: CGFloat = -1, height: CGFloat = -1) {
		let width = width == -1 ? self.width : width; let height = height == -1 ? self.height : height
		self.frame = CGRect(x: parent.width-width+dx, y: dy, width: width, height: height)
	}
	func bottomLeft(dx: CGFloat = 0, dy: CGFloat = 0, width: CGFloat = -1, height: CGFloat = -1) {
		let width = width == -1 ? self.width : width; let height = height == -1 ? self.height : height
		self.frame = CGRect(x: dx, y: parent.height-height+dy, width: width, height: height)
	}
	func bottomRight(dx: CGFloat = 0, dy: CGFloat = 0, width: CGFloat = -1, height: CGFloat = -1) {
		let width = width == -1 ? self.width : width; let height = height == -1 ? self.height : height
		self.frame = CGRect(x: parent.width-width+dx, y: parent.height-height+dy, width: width, height: height)
	}
	func center(dx: CGFloat = 0, dy: CGFloat = 0, size: CGSize) {
		center(dx: dx, dy: dy, width: size.width, height: size.height)
	}
	func right(dx: CGFloat = 0, dy: CGFloat = 0, size: CGSize) {
		right(dx: dx, dy: dy, width: size.width, height: size.height)
	}
	func left(dx: CGFloat = 0, dy: CGFloat = 0, size: CGSize) {
		left(dx: dx, dy: dy, width: size.width, height: size.height)
	}
	func top(dx: CGFloat = 0, dy: CGFloat = 0, size: CGSize) {
		top(dx: dx, dy: dy, width: size.width, height: size.height)
	}
	func bottom(dx: CGFloat = 0, dy: CGFloat = 0, size: CGSize) {
		bottom(dx: dx, dy: dy, width: size.width, height: size.height)
	}
	func topLeft(dx: CGFloat = 0, dy: CGFloat = 0, size: CGSize) {
		topLeft(dx: dx, dy: dy, width: size.width, height: size.height)
	}
	func topRight(dx: CGFloat = 0, dy: CGFloat = 0, size: CGSize) {
		topRight(dx: dx, dy: dy, width: size.width, height: size.height)
	}
	func bottomLeft(dx: CGFloat = 0, dy: CGFloat = 0, size: CGSize) {
		bottomLeft(dx: dx, dy: dy, width: size.width, height: size.height)
	}
	func bottomRight(dx: CGFloat = 0, dy: CGFloat = 0, size: CGSize) {
		bottomRight(dx: dx, dy: dy, width: size.width, height: size.height)
	}

	var top: CGFloat {
		return frame.origin.y
	}
	var bottom: CGFloat {
		return frame.origin.y + frame.size.height
	}
	var left: CGFloat {
		return frame.origin.x
	}
	var right: CGFloat {
		return frame.origin.x + frame.size.width
	}
	var width: CGFloat {
		return bounds.size.width
	}
	var height: CGFloat {
		return bounds.size.height
	}
	
	func pointOnScreen(_ point: CGPoint) -> CGPoint {
		return convert(point, to: Screen.keyWindow)
	}
	func rectOnScreen(_ rect: CGRect) -> CGRect {
		return CGRect(origin: pointOnScreen(rect.origin), size: rect.size)
	}
}
