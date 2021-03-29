//
//  Pen.swift
//  Acheron
//
//  Created by Joe Charlier on 3/8/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import UIKit

public class Pen: NSObject {
	public let attributes: [NSAttributedString.Key:Any]
	
	public var font: UIFont { attributes[.font] as! UIFont }
	public var color: UIColor { attributes[.foregroundColor] as! UIColor }
	public var style: NSParagraphStyle { attributes[.paragraphStyle] as! NSParagraphStyle }
	public var alignment: NSTextAlignment { style.alignment }
	public var kern: CGFloat? { attributes[.kern] as? CGFloat }
	
	public init(font: UIFont = UIFont.systemFont(ofSize: 16), color: UIColor = UIColor.black, alignment: NSTextAlignment = .left, style: NSParagraphStyle = NSParagraphStyle.default, kern: CGFloat? = nil) {
		var mutable: [NSAttributedString.Key:Any] = [:]
		mutable[.font] = font
		mutable[.foregroundColor] = color
		let mutableStyle: NSMutableParagraphStyle = style.mutableCopy() as! NSMutableParagraphStyle
		mutableStyle.alignment = alignment
		mutable[.paragraphStyle] = mutableStyle
		if let kern = kern { mutable[.kern] = kern }
		attributes = mutable
	}

	public func clone(font: UIFont? = nil, color: UIColor? = nil, alignment: NSTextAlignment? = nil, style: NSParagraphStyle? = nil, kern: CGFloat? = nil) -> Pen {
		return Pen(font: font ?? self.font, color: color ?? self.color, alignment: alignment ?? self.alignment, style: style ?? self.style, kern: kern ?? self.kern)
	}
}
