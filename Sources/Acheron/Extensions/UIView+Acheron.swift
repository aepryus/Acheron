//
//  UIView+Acheron.swift
//  Acheron
//
//  Created by Joe Charlier on 3/8/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

#if canImport(UIKit)

import UIKit

public extension UIView {
    
    var s: CGFloat { Screen.s }
    func s(_ x: CGFloat) -> CGFloat { round(x*s*Screen.scale)/Screen.scale }
    
    private var parent: CGSize {
        if let parent = superview {
            return parent.bounds.size
        } else {
            return Screen.size
        }
    }

    /// Whether the app is laying out right-to-left (Arabic, Hebrew, Urdu, …).
    ///
    /// Read once per process — a language change requires a relaunch anyway.
    /// Deliberately NOT `UIApplication.shared.userInterfaceLayoutDirection`,
    /// which is unavailable in app extensions; this spelling compiles into
    /// widgets, controls and notification-service targets too.
    static let layoutIsRTL: Bool = UIView.userInterfaceLayoutDirection(for: .unspecified) == .rightToLeft

    /// Every anchor below computes its rect in left-to-right terms and hands it
    /// here, which mirrors x within the parent when the app is RTL. One flip in
    /// one place — `left(dx:)` becomes `right(dx:)`, a `center(dx:)` nudge
    /// reverses, and anything x-symmetric is left untouched by the arithmetic.
    ///
    /// `overrideLTR: true` opts out, for the rare thing whose direction is
    /// physical rather than linguistic — a media scrubber, or a row of digit
    /// boxes (numerals read left-to-right even inside RTL text).
    private func place(_ rect: CGRect, _ overrideLTR: Bool) {
        guard Self.layoutIsRTL && !overrideLTR else { frame = rect; return }
        frame = CGRect(x: parent.width-rect.width-rect.origin.x, y: rect.origin.y, width: rect.width, height: rect.height)
    }

    func center(dx: CGFloat = 0, dy: CGFloat = 0, width: CGFloat = -1, height: CGFloat = -1, overrideLTR: Bool = false) {
        let width = width == -1 ? self.width : width; let height = height == -1 ? self.height : height
        place(CGRect(x: (parent.width-width)/2+dx, y: (parent.height-height)/2+dy, width: width, height: height), overrideLTR)
    }
    func right(dx: CGFloat = 0, dy: CGFloat = 0, width: CGFloat = -1, height: CGFloat = -1, overrideLTR: Bool = false) {
        let width = width == -1 ? self.width : width; let height = height == -1 ? self.height : height
        place(CGRect(x: parent.width-width+dx, y: (parent.height-height)/2+dy, width: width, height: height), overrideLTR)
    }
    func left(dx: CGFloat = 0, dy: CGFloat = 0, width: CGFloat = -1, height: CGFloat = -1, overrideLTR: Bool = false) {
        let width = width == -1 ? self.width : width; let height = height == -1 ? self.height : height
        place(CGRect(x: dx, y: (parent.height-height)/2+dy, width: width, height: height), overrideLTR)
    }
    func top(dx: CGFloat = 0, dy: CGFloat = 0, width: CGFloat = -1, height: CGFloat = -1, overrideLTR: Bool = false) {
        let width = width == -1 ? self.width : width; let height = height == -1 ? self.height : height
        place(CGRect(x: (parent.width-width)/2+dx, y: dy, width: width, height: height), overrideLTR)
    }
    func bottom(dx: CGFloat = 0, dy: CGFloat = 0, width: CGFloat = -1, height: CGFloat = -1, overrideLTR: Bool = false) {
        let width = width == -1 ? self.width : width; let height = height == -1 ? self.height : height
        place(CGRect(x: (parent.width-width)/2+dx, y: parent.height-height+dy, width: width, height: height), overrideLTR)
    }
    func topLeft(dx: CGFloat = 0, dy: CGFloat = 0, width: CGFloat = -1, height: CGFloat = -1, overrideLTR: Bool = false) {
        let width = width == -1 ? self.width : width; let height = height == -1 ? self.height : height
        place(CGRect(x: dx, y: dy, width: width, height: height), overrideLTR)
    }
    func topRight(dx: CGFloat = 0, dy: CGFloat = 0, width: CGFloat = -1, height: CGFloat = -1, overrideLTR: Bool = false) {
        let width = width == -1 ? self.width : width; let height = height == -1 ? self.height : height
        place(CGRect(x: parent.width-width+dx, y: dy, width: width, height: height), overrideLTR)
    }
    func bottomLeft(dx: CGFloat = 0, dy: CGFloat = 0, width: CGFloat = -1, height: CGFloat = -1, overrideLTR: Bool = false) {
        let width = width == -1 ? self.width : width; let height = height == -1 ? self.height : height
        place(CGRect(x: dx, y: parent.height-height+dy, width: width, height: height), overrideLTR)
    }
    func bottomRight(dx: CGFloat = 0, dy: CGFloat = 0, width: CGFloat = -1, height: CGFloat = -1, overrideLTR: Bool = false) {
        let width = width == -1 ? self.width : width; let height = height == -1 ? self.height : height
        place(CGRect(x: parent.width-width+dx, y: parent.height-height+dy, width: width, height: height), overrideLTR)
    }

    func center(dx: CGFloat = 0, dy: CGFloat = 0, size: CGSize, overrideLTR: Bool = false) {
        center(dx: dx, dy: dy, width: size.width, height: size.height, overrideLTR: overrideLTR)
    }
    func right(dx: CGFloat = 0, dy: CGFloat = 0, size: CGSize, overrideLTR: Bool = false) {
        right(dx: dx, dy: dy, width: size.width, height: size.height, overrideLTR: overrideLTR)
    }
    func left(dx: CGFloat = 0, dy: CGFloat = 0, size: CGSize, overrideLTR: Bool = false) {
        left(dx: dx, dy: dy, width: size.width, height: size.height, overrideLTR: overrideLTR)
    }
    func top(dx: CGFloat = 0, dy: CGFloat = 0, size: CGSize, overrideLTR: Bool = false) {
        top(dx: dx, dy: dy, width: size.width, height: size.height, overrideLTR: overrideLTR)
    }
    func bottom(dx: CGFloat = 0, dy: CGFloat = 0, size: CGSize, overrideLTR: Bool = false) {
        bottom(dx: dx, dy: dy, width: size.width, height: size.height, overrideLTR: overrideLTR)
    }
    func topLeft(dx: CGFloat = 0, dy: CGFloat = 0, size: CGSize, overrideLTR: Bool = false) {
        topLeft(dx: dx, dy: dy, width: size.width, height: size.height, overrideLTR: overrideLTR)
    }
    func topRight(dx: CGFloat = 0, dy: CGFloat = 0, size: CGSize, overrideLTR: Bool = false) {
        topRight(dx: dx, dy: dy, width: size.width, height: size.height, overrideLTR: overrideLTR)
    }
    func bottomLeft(dx: CGFloat = 0, dy: CGFloat = 0, size: CGSize, overrideLTR: Bool = false) {
        bottomLeft(dx: dx, dy: dy, width: size.width, height: size.height, overrideLTR: overrideLTR)
    }
    func bottomRight(dx: CGFloat = 0, dy: CGFloat = 0, size: CGSize, overrideLTR: Bool = false) {
        bottomRight(dx: dx, dy: dy, width: size.width, height: size.height, overrideLTR: overrideLTR)
    }

    var top: CGFloat { frame.origin.y }
    var bottom: CGFloat { frame.origin.y + frame.size.height }
    /// Mirrored to match the anchors, so chaining reads the same in both
    /// directions: a view placed by `left(dx: 12)` reports `left == 12` whether
    /// the app runs LTR or RTL, and `sibling.right+s(12)` lands where you meant.
    /// Raw `frame.minX` / `frame.maxX` are still there when you want the
    /// physical edge.
    var left: CGFloat { Self.layoutIsRTL ? parent.width-frame.maxX : frame.minX }
    var right: CGFloat { Self.layoutIsRTL ? parent.width-frame.minX : frame.maxX }
    var width: CGFloat { bounds.size.width }
    var height: CGFloat { bounds.size.height }
    
    func pointOnScreen(_ point: CGPoint) -> CGPoint { convert(point, to: Screen.keyWindow) }
    func rectOnScreen(_ rect: CGRect) -> CGRect { CGRect(origin: pointOnScreen(rect.origin), size: rect.size) }

    func asImage() -> UIImage { UIGraphicsImageRenderer(bounds: bounds).image { layer.render(in: $0.cgContext) } }
}

#endif
