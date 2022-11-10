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
    public var top: CGFloat { frame.origin.y }
    public var bottom: CGFloat { frame.origin.y + frame.size.height }
    public var left: CGFloat { frame.origin.x }
    public var right: CGFloat { frame.origin.x + frame.size.width }
    public var width: CGFloat { bounds.size.width }
    public var height: CGFloat { bounds.size.height }
}

#endif
