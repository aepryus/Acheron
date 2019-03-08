//
//  UIColor+Acheron.swift
//  Acheron
//
//  Created by Joe Charlier on 3/8/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

extension UIColor {
	public func alpha(_ alpha: CGFloat) -> UIColor {
		return withAlphaComponent(alpha)
	}
	public func shade(_ percent: Float) -> UIColor {
		return RGB.shade(color: self, percent: percent)
	}
	public func tint(_ percent: Float) -> UIColor {
		return RGB.tint(color: self, percent: percent)
	}
}
