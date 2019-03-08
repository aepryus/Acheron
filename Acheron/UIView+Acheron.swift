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
	
	public var s: CGFloat {
		return Screen.s
	}
	
	private var parent: CGSize {
		if let parent = superview {
			return parent.bounds.size
		} else {
			return UIScreen.main.bounds.size
		}
	}
	
	public func center(offset: UIOffset, size: CGSize) {
		self.frame = CGRect(x: (parent.width-size.width)/2+offset.horizontal, y: (parent.height-size.height)/2+offset.vertical, width: size.width, height: size.height)
	}
	public func right(offset: UIOffset, size: CGSize) {
		self.frame = CGRect(x: parent.width-size.width+offset.horizontal, y: (parent.height-size.height)/2+offset.vertical, width: size.width, height: size.height)
	}
	public func left(offset: UIOffset, size: CGSize) {
		self.frame = CGRect(x: offset.horizontal, y: (parent.height-size.height)/2+offset.vertical, width: size.width, height: size.height)
	}
	public func top(offset: UIOffset, size: CGSize) {
		self.frame = CGRect(x: (parent.width-size.width)/2+offset.horizontal, y: offset.vertical, width: size.width, height: size.height)
	}
	public func bottom(offset: UIOffset, size: CGSize) {
		self.frame = CGRect(x: (parent.width-size.width)/2+offset.horizontal, y: parent.height-size.height+offset.vertical, width: size.width, height: size.height)
	}
	public func topLeft(offset: UIOffset, size: CGSize) {
		self.frame = CGRect(x: offset.horizontal, y: offset.vertical, width: size.width, height: size.height)
	}
	public func topRight(offset: UIOffset, size: CGSize) {
		self.frame = CGRect(x: parent.width-size.width+offset.horizontal, y: offset.vertical, width: size.width, height: size.height)
	}
	public func bottomLeft(offset: UIOffset, size: CGSize) {
		self.frame = CGRect(x: offset.horizontal, y: parent.height-size.height+offset.vertical, width: size.width, height: size.height)
	}
	public func bottomRight(offset: UIOffset, size: CGSize) {
		self.frame = CGRect(x: parent.width-size.width+offset.horizontal, y: parent.height-size.height+offset.vertical, width: size.width, height: size.height)
	}
	
	public var top: CGFloat {
		return frame.origin.y
	}
	public var bottom: CGFloat {
		return frame.origin.y + frame.size.height
	}
	public var left: CGFloat {
		return frame.origin.x
	}
	public var right: CGFloat {
		return frame.origin.x + frame.size.width
	}
	public var width: CGFloat {
		return bounds.size.width
	}
	public var height: CGFloat {
		return bounds.size.height
	}
	
	public func pointOnScreen(_ point: CGPoint) -> CGPoint {
		let next = frame.origin + point
		guard let view = superview else {return next}
		return view.pointOnScreen(next)
	}
	public func rectOnScreen(_ rect: CGRect) -> CGRect {
		return CGRect(origin: pointOnScreen(rect.origin), size: rect.size)
	}
}
