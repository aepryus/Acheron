//
//  Pen.swift
//  Acheron
//
//  Created by Joe Charlier on 3/8/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

#if canImport(UIKit)

import UIKit

public class Pen: NSObject {
    public let attributes: [NSAttributedString.Key:Any]
    
    public var font: UIFont { attributes[.font] as! UIFont }
    public var color: UIColor { attributes[.foregroundColor] as! UIColor }
    public var alignment: NSTextAlignment { style.alignment }
    public var style: NSParagraphStyle { attributes[.paragraphStyle] as! NSParagraphStyle }
    public var kern: CGFloat? { attributes[.kern] as? CGFloat }
    public var baselineOffset: CGFloat? { attributes[.baselineOffset] as? CGFloat }
    
    public init(font: UIFont = UIFont.systemFont(ofSize: 16), color: UIColor = UIColor.black, alignment: NSTextAlignment = .left, style: NSParagraphStyle = NSParagraphStyle.default, kern: CGFloat? = nil, baselineOffset: CGFloat? = nil) {
        let mutableStyle: NSMutableParagraphStyle = style.mutableCopy() as! NSMutableParagraphStyle
        mutableStyle.alignment = alignment
        var attributes: [NSAttributedString.Key:Any] = [.font:font, .foregroundColor:color, .paragraphStyle:mutableStyle]
        if let kern = kern { attributes[.kern] = kern }
        if let baselineOffset = baselineOffset { attributes[.baselineOffset] = baselineOffset }
        self.attributes = attributes
    }

    public func clone(font: UIFont? = nil, color: UIColor? = nil, alignment: NSTextAlignment? = nil, style: NSParagraphStyle? = nil, kern: CGFloat? = nil, baselineOffset: CGFloat? = nil) -> Pen {
        return Pen(font: font ?? self.font, color: color ?? self.color, alignment: alignment ?? self.alignment, style: style ?? self.style, kern: kern ?? self.kern, baselineOffset: baselineOffset ?? self.baselineOffset)
    }
    
    public func format(_ string: String) -> NSMutableAttributedString {
        let sb: NSMutableAttributedString = NSMutableAttributedString()
        sb.append(string, pen: self)
        return sb
    }
    public func size(text: String, width: CGFloat) -> CGSize {
        (text as NSString).boundingRect(
            with: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin , .usesFontLeading],
            attributes: [.font : font],
            context: nil
        ).size
    }
}

#endif
