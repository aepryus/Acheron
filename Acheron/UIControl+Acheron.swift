//
//  UIControl+Acheron.swift
//  Acheron
//
//  Created by Joe Charlier on 3/8/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import UIKit

extension UIControl {
	@objc public func addAction(for controlEvents: UIControl.Event = .touchUpInside, _ closure: @escaping()->()) {
		if #available(iOS 14.0, *) {
			addAction(UIAction { (action: UIAction) in closure() }, for: controlEvents)
		} else {
			@objc class ClosureSleeve: NSObject {
				let closure:()->()
				init(_ closure: @escaping()->()) { self.closure = closure }
				@objc func invoke() { closure() }
			}
			let sleeve = ClosureSleeve(closure)
			addTarget(sleeve, action: #selector(ClosureSleeve.invoke), for: controlEvents)
			objc_setAssociatedObject(self, "\(UUID())", sleeve, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
		}
	}
}
