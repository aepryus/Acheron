//
//  CGSize+Acheron.swift
//  Acheron
//
//  Created by Joe Charlier on 1/31/25.
//

import UIKit

public extension CGSize {
    static func * (p: CGSize, q: CGFloat) -> CGSize { CGSize(width: p.width*q, height: p.height*q) }
    static func / (p: CGSize, q: CGFloat) -> CGSize { CGSize(width: p.width/q, height: p.height/q) }
}
