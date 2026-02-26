//
//  RGB.swift
//  Acheron
//
//  Created by Joe Charlier on 3/8/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

#if canImport(UIKit)

import UIKit

public struct RGB {
    let r: CGFloat
    let g: CGFloat
    let b: CGFloat
    let a: CGFloat
    public let uiColor: UIColor
    
    private init(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat, uiColor: UIColor) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
        self.uiColor = uiColor
    }
    public init(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        let uiColor = UIColor(red: r, green: g, blue: b, alpha: a)
        self.init(r: r, g: g, b: b, a: a, uiColor: uiColor)
    }
    public init(r: CGFloat, g: CGFloat, b: CGFloat) {
        self.init(r: r, g: g, b: b, a: 1)
    }
    public init(r: Int, g: Int, b: Int) {
        self.init(r: CGFloat(r)/255, g: CGFloat(g)/255, b: CGFloat(b)/255)
    }
    public init(uiColor: UIColor) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        self.init(r: r, g: g, b: b, a: a, uiColor: uiColor)
    }
    
    public static func + (p: RGB, q: RGB) -> RGB { RGB(r: p.r+q.r, g: p.g+q.g, b: p.b+q.b, a: p.a+q.a) }
    public static func - (p: RGB, q: RGB) -> RGB { RGB(r: p.r-q.r, g: p.g-q.g, b: p.b-q.b, a: p.a-q.a) }
    public static func * (p: RGB, q: CGFloat) -> RGB { RGB(r: p.r*q, g: p.g*q, b: p.b*q, a: p.a*q) }
    
    public func blend (rgb: RGB, percent: CGFloat) -> RGB { self + (rgb - self) * percent }
    public func tint(_ percent: CGFloat) -> RGB { blend(rgb: RGB.white, percent: percent) }
    public func tone(_ percent: CGFloat) -> RGB { blend(rgb: RGB.grey, percent: percent) }
    public func shade(_ percent: CGFloat) -> RGB { blend(rgb: RGB.black, percent: percent) }
    
    public var cgColor: CGColor { uiColor.cgColor }
    
// Static ==========================================================================================
    public static var black = RGB(r: 0, g: 0, b: 0, a: 1)
    public static var white = RGB(r: 1, g: 1, b: 1, a: 1)
    public static var grey = RGB(r: 0.5, g: 0.5, b: 0.5, a: 1)
    
    public static func tint(color: UIColor, percent: CGFloat) -> UIColor { RGB(uiColor: color).blend(rgb: white, percent: percent).uiColor }
    public static func tone(color: UIColor, percent: CGFloat) -> UIColor { RGB(uiColor: color).blend(rgb: grey, percent: percent).uiColor }
    public static func shade(color: UIColor, percent: CGFloat) -> UIColor { RGB(uiColor: color).blend(rgb: black, percent: percent).uiColor }
    public static func blend(color: UIColor, with: UIColor, percent: CGFloat) -> UIColor { RGB(uiColor: color).blend(rgb: RGB(uiColor: with), percent: percent).uiColor }
}

#endif
