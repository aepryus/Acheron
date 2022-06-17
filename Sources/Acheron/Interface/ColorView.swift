//
//  File.swift
//  
//
//  Created by Joe Charlier on 6/15/22.
//

import UIKit

public class ColorView: UIView {
	public init(_ color: UIColor) {
		super.init(frame: .zero)
		backgroundColor = color
	}
	required init?(coder: NSCoder) { fatalError() }
}
