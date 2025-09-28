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
    private let blocking: Bool
    private let onTrip: ()->()
    private var visualEffectView: UIVisualEffectView?
    private var colorOverlayView: UIView?
    
    public init(blocking: Bool = false, onTrip: @escaping ()->()) {
        self.blocking = blocking
        self.onTrip = onTrip
        super.init()
    }
    
    public func paint(color: UIColor? = nil, blur: CGFloat = 0) {
        visualEffectView?.removeFromSuperview()
        colorOverlayView?.removeFromSuperview()

        if blur > 0 {
            visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
            guard let visualEffectView else { return }
            visualEffectView.frame = bounds
            visualEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            visualEffectView.alpha = min(max(blur, 0), 1)
            addSubview(visualEffectView)
        }
        
        if let color {
            colorOverlayView = UIView()
            guard let colorOverlayView else { return }
            colorOverlayView.backgroundColor = color
            colorOverlayView.frame = bounds
            colorOverlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            colorOverlayView.isUserInteractionEnabled = false
            addSubview(colorOverlayView)
        }
    }
    
// UIView ==========================================================================================
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let event, event.type == .touches else { return nil }
        let view = super.hitTest(point, with: event)
        if view !== self && view != colorOverlayView && view != visualEffectView { return view }
        onTrip()
        return blocking ? self : nil
    }
}

#endif
