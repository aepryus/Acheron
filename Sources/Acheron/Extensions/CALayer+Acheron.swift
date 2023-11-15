//
//  CALayer+Acheron.swift
//  Acheron
//
//  Created by Joe Charlier on 3/8/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

#if canImport(UIKit)

import UIKit

extension CALayer {
    private var parent: CGSize {
        if let parent = superview {
            return parent.bounds.size
        } else {
            return Screen.size
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

    public var top: CGFloat { frame.origin.y }
    public var bottom: CGFloat { frame.origin.y + frame.size.height }
    public var left: CGFloat { frame.origin.x }
    public var right: CGFloat { frame.origin.x + frame.size.width }
    public var width: CGFloat { bounds.size.width }
    public var height: CGFloat { bounds.size.height }
}

#endif
