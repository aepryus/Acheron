//
//  CGPoint+Acheron.swift
//  Acheron
//
//  Created by Joe Charlier on 3/8/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

#if canImport(UIKit)

import UIKit

public extension CGPoint {
	static func + (a: CGPoint, b: CGPoint) -> CGPoint { CGPoint(x: a.x+b.x, y: a.y+b.y) }
	static func - (a: CGPoint, b: CGPoint) -> CGPoint { CGPoint(x: a.x-b.x, y: a.y-b.y) }
	static func * (a: CGPoint, b: CGFloat) -> CGPoint { CGPoint(x: a.x*b, y: a.y*b) }
	static func * (a: CGFloat, b: CGPoint) -> CGPoint { CGPoint(x: a*b.x, y: a*b.y) }
	static func / (a: CGPoint, b: CGFloat) -> CGPoint { CGPoint(x: a.x/b, y: a.y/b) }
	
	func perpendicular() -> CGPoint { CGPoint(x: y, y: -x) }
	func lengthSquared() -> CGFloat { x*x+y*y }
	func length() -> CGFloat { sqrt(lengthSquared()) }
	func ofLength(_ a: CGFloat) -> CGPoint { a*unit() }

	func unit() -> CGPoint {
		let l = length()
		return CGPoint(x: x/l, y: y/l)
	}

	static func point(theta: CGFloat) -> CGPoint { CGPoint(x: cos(theta), y: sin(theta)) }
}

#endif
