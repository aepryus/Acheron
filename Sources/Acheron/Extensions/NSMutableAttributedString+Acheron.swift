//
//  NSMutableAttributedString+Acheron.swift
//  Acheron
//
//  Created by Joe Charlier on 4/16/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

#if canImport(UIKit)

import UIKit

public extension NSMutableAttributedString {
	@discardableResult
	func append(_ string: String, pen: Pen) -> NSMutableAttributedString {
		self.append(NSAttributedString(string: string, attributes: pen.attributes))
		return self
	}
	@discardableResult
	func append(image: UIImage) -> NSMutableAttributedString{
		let attachment = NSTextAttachment()
		attachment.image = image
		self.append(NSAttributedString(attachment: attachment))
		return self
	}
}

#endif
