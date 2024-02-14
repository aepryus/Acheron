//
//  TripWire.swift
//  Acheron
//
//  Created by Joe Charlier on 3/14/18.
//  Copyright © 2018 Aepryus Software. All rights reserved.
//

#if canImport(UIKit)

import UIKit

public class TripWire: AEView {
    public let onTrip: ()->()
    
    public init(onTrip: @escaping ()->()) {
        self.onTrip = onTrip
        super.init()
    }
    
    override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let event, event.type == .touches else { return nil }
        let view = super.hitTest(point, with: event)
        if view !== self { return view }
        onTrip()
        return nil
    }
}

#endif
