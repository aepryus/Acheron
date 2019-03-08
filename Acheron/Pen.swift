//
//  Pen.swift
//  Acheron
//
//  Created by Joe Charlier on 3/8/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import UIKit

public class Pen {
	public var attributes = [NSAttributedString.Key:Any]()
	
	public var font: UIFont {
		set {attributes[NSAttributedString.Key.font] = newValue}
		get {return attributes[NSAttributedString.Key.font] as! UIFont}
	}
	public var color: UIColor {
		set {attributes[NSAttributedString.Key.foregroundColor] = newValue}
		get {return attributes[NSAttributedString.Key.foregroundColor] as! UIColor}
	}
	public var alignment: NSTextAlignment {
		set {style.alignment = newValue}
		get {return style.alignment}
	}
	public var style: NSMutableParagraphStyle {
		set {attributes[NSAttributedString.Key.paragraphStyle] = newValue}
		get {return attributes[NSAttributedString.Key.paragraphStyle] as! NSMutableParagraphStyle}
	}
	
	public init (font: UIFont) {
		self.font = font
		self.color = UIColor.white
		self.style = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
		self.style.lineBreakMode = .byWordWrapping
	}
	public convenience init() {
		self.init(font: UIFont.systemFont(ofSize: 12))
	}
	
	public func copy() -> Pen {
		let pen = Pen(font: font)
		pen.color = color
		pen.alignment = alignment
		pen.style = style.mutableCopy() as! NSMutableParagraphStyle
		return pen
	}
}
