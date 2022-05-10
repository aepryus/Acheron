//
//  UIViewController+Acheron.swift
//  Acheron
//
//  Created by Joe Charlier on 3/8/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

#if canImport(UIKit)

import UIKit

public extension UIViewController {
	var s: CGFloat { Screen.s }
	var safeTop: CGFloat { Screen.safeTop }
	var safeBottom: CGFloat { Screen.safeBottom }
}

#endif
