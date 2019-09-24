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
	
	var font: UIFont {return attributes[NSAttributedString.Key.font] as! UIFont}
	var color: UIColor {return attributes[NSAttributedString.Key.foregroundColor] as! UIColor}
	var style: NSParagraphStyle {return attributes[NSAttributedString.Key.paragraphStyle] as! NSParagraphStyle}
	var alignment: NSTextAlignment {return style.alignment}
	
	public init(font: UIFont = UIFont.systemFont(ofSize: 16), color: UIColor = UIColor.black, alignment: NSTextAlignment = .left, style: NSParagraphStyle = NSParagraphStyle.default) {
		var mutable: [NSAttributedString.Key:Any] = [:]
		mutable[NSAttributedString.Key.font] = font
		mutable[NSAttributedString.Key.foregroundColor] = color
		let mutableStyle: NSMutableParagraphStyle = style.mutableCopy() as! NSMutableParagraphStyle
		mutableStyle.alignment = alignment
		mutable[NSAttributedString.Key.paragraphStyle] = mutableStyle
		attributes = mutable
	}
	@objc public convenience init(font: UIFont, alignment: NSTextAlignment) {
		self.init(font: font, color: UIColor.black, alignment: alignment)
	}

	public func clone(font: UIFont? = nil, color: UIColor? = nil, alignment: NSTextAlignment? = nil, style: NSParagraphStyle? = nil) -> Pen {
		return Pen(font: font ?? self.font, color: color ?? self.color, alignment: alignment ?? self.alignment, style: style ?? self.style)
	}
}
