//
//  UIControl+Acheron.swift
//  Acheron
//
//  Created by Joe Charlier on 3/8/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import UIKit

fileprivate class ClosureSleeve {
	let closure:()->()
	init(_ closure: @escaping()->()) { self.closure = closure }
	@objc func invoke() { closure() }
}

extension UIControl {
	@objc public func addAction(for controlEvents: UIControl.Event = .touchUpInside, _ closure: @escaping()->()) {
		let sleeve = ClosureSleeve(closure)
		addTarget(sleeve, action: #selector(ClosureSleeve.invoke), for: controlEvents)
		objc_setAssociatedObject(self, "[\(arc4random())]", sleeve, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
	}
}
