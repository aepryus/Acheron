//
//  UIImageView+Acheron.swift
//  Acheron
//
//  Created by Joe Charlier on 3/25/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import UIKit

public extension UIImageView {
	static var urlLookup: [UInt:String] = [:]
	
	var identifier: UInt { UInt(bitPattern: ObjectIdentifier(self)) }
	
	func loadImage(url: String, placeholder: UIImage? = nil, complete: @escaping ()->() = {}) {
		UIImage.loadImage(url: url) { (image: UIImage) in
			UIImageView.urlLookup[identifier] = nil
			self.image = image
			complete()
		} willLoad: {
			UIImageView.urlLookup[identifier] = url
			image = placeholder
		} finishedLoading: { (image: UIImage) in
			guard UIImageView.urlLookup[self.identifier] == url else { return }
			self.image = image
			complete()
		}
	}
	@objc func loadImage(atURL: URL?, placeholder: UIImage? = nil, complete: @escaping ()->() = {}) {
		guard let atURL = atURL else { return }
		loadImage(url: atURL.absoluteString, placeholder: placeholder, complete: complete)
	}
}
