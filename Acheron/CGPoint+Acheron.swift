//
//  CGPoint+Acheron.swift
//  Acheron
//
//  Created by Joe Charlier on 3/8/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import UIKit

public extension CGPoint {
	public static func + (a: CGPoint, b: CGPoint) -> CGPoint {
		return CGPoint(x: a.x+b.x, y: a.y+b.y)
	}
	public static func - (a: CGPoint, b: CGPoint) -> CGPoint {
		return CGPoint(x: a.x-b.x, y: a.y-b.y)
	}
	public static func * (a: CGPoint, b: CGFloat) -> CGPoint {
		return CGPoint(x: a.x*b, y: a.y*b)
	}
	public static func / (a: CGPoint, b: CGFloat) -> CGPoint {
		return CGPoint(x: a.x/b, y: a.y/b)
	}
	
	func perpendicular() -> CGPoint {
		return CGPoint(x: y, y: -x)
	}
	func lenSq() -> CGFloat {
		return x*x+y*y
	}
	func len() -> CGFloat {
		return sqrt(lenSq())
	}
	func unit() -> CGPoint {
		let l = len()
		return CGPoint(x: x/l, y: y/l)
	}
}
