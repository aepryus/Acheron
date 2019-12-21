//
//  CGPoint+Acheron.swift
//  Acheron
//
//  Created by Joe Charlier on 3/8/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import UIKit

public extension CGPoint {
	static func + (a: CGPoint, b: CGPoint) -> CGPoint {
		return CGPoint(x: a.x+b.x, y: a.y+b.y)
	}
	static func - (a: CGPoint, b: CGPoint) -> CGPoint {
		return CGPoint(x: a.x-b.x, y: a.y-b.y)
	}
	static func * (a: CGPoint, b: CGFloat) -> CGPoint {
		return CGPoint(x: a.x*b, y: a.y*b)
	}
	static func * (a: CGFloat, b: CGPoint) -> CGPoint {
		return CGPoint(x: a*b.x, y: a*b.y)
	}
	static func / (a: CGPoint, b: CGFloat) -> CGPoint {
		return CGPoint(x: a.x/b, y: a.y/b)
	}
	
	func perpendicular() -> CGPoint {
		return CGPoint(x: y, y: -x)
	}
	func lengthSquared() -> CGFloat {
		return x*x+y*y
	}
	func length() -> CGFloat {
		return sqrt(lengthSquared())
	}
	func unit() -> CGPoint {
		let l = length()
		return CGPoint(x: x/l, y: y/l)
	}
	static func point(theta: CGFloat) -> CGPoint {
		return CGPoint(x: cos(theta), y: sin(theta))
	}
}
