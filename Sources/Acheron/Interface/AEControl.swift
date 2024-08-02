//
//  AEControl.swift
//  Acheron
//
//  Created by Joe Charlier on 2/13/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

#if canImport(UIKit)

import UIKit

open class AEControl: UIControl {
    public init() { super.init(frame: .zero) }
    @available(*, unavailable)
    required public init?(coder aDecoder: NSCoder) { fatalError() }
}

#endif
