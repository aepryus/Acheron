//
//  CGRect+Acheron.swift
//  MacENCx64
//
//  Created by Joe Charlier on 2023/06/16.
//

#if canImport(UIKit)

import UIKit

public extension CGRect {
    var top: CGFloat { origin.y }
    var bottom: CGFloat { origin.y + size.height }
    var left: CGFloat { origin.x }
    var right: CGFloat { origin.x + size.width }
    var width: CGFloat { size.width }
    var height: CGFloat { size.height }
    
    static func * (p: CGRect, q: CGFloat) -> CGRect { CGRect(x: p.left*q, y: p.top*q, width: p.width*q, height: p.height*q) }
}

#endif
