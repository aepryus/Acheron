//
//  TripWire.swift
//  Acheron
//
//  Created by Joe Charlier on 3/14/18.
//  Copyright © 2018 Aepryus Software. All rights reserved.
//

import UIKit

class TripWire: UIView {
	var onTrip: ()->()
	
	init(frame: CGRect = CGRect.zero, onTrip: @escaping ()->()) {
		self.onTrip = onTrip
		super.init(frame: frame == CGRect.zero ? UIScreen.main.bounds : frame)
	}
	required init?(coder aDecoder: NSCoder) {fatalError()}
	
	override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
		let view = super.hitTest(point, with: event)
		if view !== self {return view}
		removeFromSuperview()
		onTrip()
		return nil
	}
}
