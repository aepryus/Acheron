//
//  NSString+Acheron.swift
//  Acheron
//
//  Created by Joe Charlier on 4/16/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import Foundation

public extension NSString {
	func draw(at point: CGPoint, pen: Pen) {
		draw(at: point, withAttributes: pen.attributes)
	}
	@objc(drawInRect:pen:) func draw(in rect: CGRect, pen: Pen) {
		draw(in: rect, withAttributes: pen.attributes)
	}
	func draw(with rect: CGRect, options: NSStringDrawingOptions, pen: Pen, context: NSStringDrawingContext?) {
		draw(with: rect, options: options, attributes: pen.attributes, context: context)
	}
	@objc func size(pen: Pen) -> CGSize {
		return size(withAttributes: pen.attributes)
	}
}
