//
//  UIColor+Acheron.swift
//  Acheron
//
//  Created by Joe Charlier on 3/8/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

#if canImport(UIKit)

import UIKit

extension UIColor {
    public func alpha(_ alpha: CGFloat) -> UIColor { withAlphaComponent(alpha) }
    public func shade(_ percent: CGFloat) -> UIColor { RGB.shade(color: self, percent: percent) }
    public func tone(_ percent: CGFloat) -> UIColor { RGB.tone(color: self, percent: percent) }
    public func tint(_ percent: CGFloat) -> UIColor { RGB.tint(color: self, percent: percent) }
    public func blend(with: UIColor, percent: CGFloat) -> UIColor { RGB.blend(color: self, with: with, percent: percent) }
    
    private convenience init(red: Int, green: Int, blue: Int) {
        self.init(red: CGFloat(red)/255, green: CGFloat(green)/255, blue: CGFloat(blue)/255, alpha: 1)
    }
    public convenience init(rgb: Int) {
        self.init(red: (rgb >> 16) & 0xFF, green: (rgb >> 8) & 0xFF, blue: rgb & 0xFF)
    }
}

#endif
