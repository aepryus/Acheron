//
//  UIView+Acheron.swift
//  Acheron
//
//  Created by Joe Charlier on 3/8/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import UIKit

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
