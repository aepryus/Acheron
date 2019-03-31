//
//  Pen.swift
//  Acheron
//
//  Created by Joe Charlier on 3/8/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import UIKit

public class Pen: NSObject {
	@objc public var attributes = [NSAttributedString.Key:Any]()
	
	@objc public var font: UIFont {
		set {attributes[NSAttributedString.Key.font] = newValue}
		get {return attributes[NSAttributedString.Key.font] as! UIFont}
	}
	@objc public var color: UIColor {
		set {attributes[NSAttributedString.Key.foregroundColor] = newValue}
		get {return attributes[NSAttributedString.Key.foregroundColor] as! UIColor}
	}
	@objc public var alignment: NSTextAlignment {
		set {style.alignment = newValue}
		get {return style.alignment}
	}
	@objc public var style: NSMutableParagraphStyle {
		set {attributes[NSAttributedString.Key.paragraphStyle] = newValue}
		get {return attributes[NSAttributedString.Key.paragraphStyle] as! NSMutableParagraphStyle}
	}
	
	@objc public init (font: UIFont) {
		super.init()
		self.font = font
		self.color = UIColor.white
		self.style = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
		self.style.lineBreakMode = .byWordWrapping
	}
	public override convenience init() {
		self.init(font: UIFont.systemFont(ofSize: 12))
	}
	
	public subscript(index: NSAttributedString.Key) -> Any? {
		get {return attributes[index]}
		set(newValue) {attributes[index] = newValue}
	}
	
	public func clone() -> Pen {
		let pen = Pen(font: font)
		pen.attributes = attributes
		return pen
	}
}
