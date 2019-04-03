//
//  UIView+Acheron.swift
//  Acheron
//
//  Created by Joe Charlier on 3/8/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import UIKit

public enum Screen {
	case dim320x480, dim320x568, dim375x667, dim414x736, dim375x812, dim414x896, dim1024x768, dim1112x834, dim1366x1024, dimOther
	
// Static ==========================================================================================
	public static var this: Screen {
		let size = UIScreen.main.bounds.size
		if size.width == 320 && size.height == 480 {return .dim320x480}			// 0.67
		
		if size.width == 320 && size.height == 568 {return .dim320x568}			// 0.56
		if size.width == 375 && size.height == 667 {return .dim375x667}
		if size.width == 414 && size.height == 736 {return .dim414x736}
		
		if size.width == 375 && size.height == 812 {return .dim375x812}			// 0.46
		if size.width == 414 && size.height == 896 {return .dim414x896}
		
		if size.width == 1024 && size.height == 768 {return .dim1024x768}		// 1.33
		if size.width == 1112 && size.height == 834 {return .dim1112x834}
		if size.width == 1366 && size.height == 1024 {return .dim1366x1024}
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
	public static var s: CGFloat {
		if Screen.iPhone {
			return Screen.width / 375
		} else {
			return Screen.width / 1024
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
	
	func center(dx: CGFloat = 0, dy: CGFloat = 0, width: CGFloat = 0, height: CGFloat = 0) {
		let width = width == 0 ? self.width : width; let height = height == 0 ? self.height : height
		frame = CGRect(x: (parent.width-width)/2+dx, y: (parent.height-height)/2+dy, width: width, height: height)
	}
	func right(dx: CGFloat = 0, dy: CGFloat = 0, width: CGFloat = 0, height: CGFloat = 0) {
		let width = width == 0 ? self.width : width; let height = height == 0 ? self.height : height
		self.frame = CGRect(x: parent.width-width+dx, y: (parent.height-height)/2+dy, width: width, height: height)
	}
	func left(dx: CGFloat = 0, dy: CGFloat = 0, width: CGFloat = 0, height: CGFloat = 0) {
		let width = width == 0 ? self.width : width; let height = height == 0 ? self.height : height
		self.frame = CGRect(x: dx, y: (parent.height-height)/2+dy, width: width, height: height)
	}
	func top(dx: CGFloat = 0, dy: CGFloat = 0, width: CGFloat = 0, height: CGFloat = 0) {
		let width = width == 0 ? self.width : width; let height = height == 0 ? self.height : height
		self.frame = CGRect(x: (parent.width-width)/2+dx, y: dy, width: width, height: height)
	}
	func bottom(dx: CGFloat = 0, dy: CGFloat = 0, width: CGFloat = 0, height: CGFloat = 0) {
		let width = width == 0 ? self.width : width; let height = height == 0 ? self.height : height
		self.frame = CGRect(x: (parent.width-width)/2+dx, y: parent.height-height+dy, width: width, height: height)
	}
	func topLeft(dx: CGFloat = 0, dy: CGFloat = 0, width: CGFloat = 0, height: CGFloat = 0) {
		let width = width == 0 ? self.width : width; let height = height == 0 ? self.height : height
		self.frame = CGRect(x: dx, y: dy, width: width, height: height)
	}
	func topRight(dx: CGFloat = 0, dy: CGFloat = 0, width: CGFloat = 0, height: CGFloat = 0) {
		let width = width == 0 ? self.width : width; let height = height == 0 ? self.height : height
		self.frame = CGRect(x: parent.width-width+dx, y: dy, width: width, height: height)
	}
	func bottomLeft(dx: CGFloat = 0, dy: CGFloat = 0, width: CGFloat = 0, height: CGFloat = 0) {
		let width = width == 0 ? self.width : width; let height = height == 0 ? self.height : height
		self.frame = CGRect(x: dx, y: parent.height-height+dy, width: width, height: height)
	}
	func bottomRight(dx: CGFloat = 0, dy: CGFloat = 0, width: CGFloat = 0, height: CGFloat = 0) {
		let width = width == 0 ? self.width : width; let height = height == 0 ? self.height : height
		self.frame = CGRect(x: parent.width-width+dx, y: parent.height-height+dy, width: width, height: height)
	}
	func center(dx: CGFloat, dy: CGFloat, size: CGSize) {
		center(dx: dx, dy: dy, width: size.width, height: size.height)
	}
	func right(dx: CGFloat, dy: CGFloat, size: CGSize) {
		right(dx: dx, dy: dy, width: size.width, height: size.height)
	}
	func left(dx: CGFloat, dy: CGFloat, size: CGSize) {
		left(dx: dx, dy: dy, width: size.width, height: size.height)
	}
	func top(dx: CGFloat, dy: CGFloat, size: CGSize) {
		top(dx: dx, dy: dy, width: size.width, height: size.height)
	}
	func bottom(dx: CGFloat, dy: CGFloat, size: CGSize) {
		bottom(dx: dx, dy: dy, width: size.width, height: size.height)
	}
	func topLeft(dx: CGFloat, dy: CGFloat, size: CGSize) {
		topLeft(dx: dx, dy: dy, width: size.width, height: size.height)
	}
	func topRight(dx: CGFloat, dy: CGFloat, size: CGSize) {
		topRight(dx: dx, dy: dy, width: size.width, height: size.height)
	}
	func bottomLeft(dx: CGFloat, dy: CGFloat, size: CGSize) {
		bottomLeft(dx: dx, dy: dy, width: size.width, height: size.height)
	}
	func bottomRight(dx: CGFloat, dy: CGFloat, size: CGSize) {
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
		return convert(point, to: UIApplication.shared.keyWindow)
	}
	func rectOnScreen(_ rect: CGRect) -> CGRect {
		return CGRect(origin: pointOnScreen(rect.origin), size: rect.size)
	}
}
