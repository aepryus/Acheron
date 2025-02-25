//
//  CGSize+Acehron.swift
//  Acheron
//
//  Created by Joe Charlier on 11/17/24.
//

#if canImport(UIKit)

import UIKit

public extension CGSize {
    static func + (a: CGSize, b: CGSize) -> CGSize { CGSize(width: a.width+b.width, height: a.height+b.height) }
    static func - (a: CGSize, b: CGSize) -> CGSize { CGSize(width: a.width-b.width, height: a.height-b.height) }
    static func * (a: CGSize, b: CGFloat) -> CGSize { CGSize(width: a.width*b, height: a.height*b) }
    static func * (a: CGFloat, b: CGSize) -> CGSize { CGSize(width: a*b.width, height: a*b.height) }
    static func / (a: CGSize, b: CGFloat) -> CGSize { CGSize(width: a.width/b, height: a.height/b) }
    static prefix func - (a: CGSize) -> CGSize { CGSize(width: -a.width, height: -a.height) }
}


#endif
