//
//  AEView.swift
//  Acheron
//
//  Created by Joe Charlier on 1/30/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

#if canImport(UIKit)

import UIKit

open class AEView: UIView {
    public init() { super.init(frame: .zero) }
    @available(*, unavailable)
    required public init?(coder aDecoder: NSCoder) { fatalError() }
}

#endif
