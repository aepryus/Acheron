//
//  File.swift
//  
//
//  Created by Joe Charlier on 6/15/22.
//

#if canImport(UIKit)

import UIKit

open class ColorView: UIView {
	public init(_ color: UIColor) {
		super.init(frame: .zero)
		backgroundColor = color
	}
    required public init?(coder: NSCoder) { fatalError() }
}

#endif
