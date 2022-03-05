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
	func append(_ string: String, pen: Pen) {
		self.append(NSAttributedString(string: string, attributes: pen.attributes))
	}
	func append(image: UIImage) {
		let attachment = NSTextAttachment()
		attachment.image = image
		self.append(NSAttributedString(attachment: attachment))
	}
}

#endif
