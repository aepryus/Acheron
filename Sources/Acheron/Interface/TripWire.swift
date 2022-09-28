//
//  TripWire.swift
//  Acheron
//
//  Created by Joe Charlier on 3/14/18.
//  Copyright © 2018 Aepryus Software. All rights reserved.
//

#if canImport(UIKit)

import UIKit

public class TripWire: UIView {
	public var onTrip: ()->()
	
	public init(frame: CGRect = CGRect.zero, onTrip: @escaping ()->()) {
		self.onTrip = onTrip
		super.init(frame: frame == CGRect.zero ? UIScreen.main.bounds : frame)
	}
	required init?(coder aDecoder: NSCoder) { fatalError() }
	
	override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
		let view = super.hitTest(point, with: event)
		if view !== self {return view}
		onTrip()
		return nil
	}
}

#endif
