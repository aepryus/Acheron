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
	
	var identifier: UInt {
		return UInt(bitPattern: ObjectIdentifier(self))
	}
	
	func loadImage(url: String, placeholder: UIImage? = nil,_ complete: @escaping ()->()) {
		UIImage.loadImage(url: url, alreadyLoaded: { (image: UIImage) in
			self.image = image
			complete()
			
		}, willLoad: {
			self.image = placeholder
			UIImageView.urlLookup[self.identifier] = url

		}, finishedLoading: { (image: UIImage) in
			guard UIImageView.urlLookup[self.identifier] == url else {return}
			self.image = image
			complete()
		})
	}
	@objc func loadImage(url: String) {
		loadImage(url: url, placeholder: nil, {})
	}
	@objc func loadImage(url: String, placeholder: UIImage?) {
		loadImage(url: url, placeholder: placeholder, {})
	}
	@objc func loadImage(atURL: URL?) {
		guard let atURL = atURL else {return}
		loadImage(url: atURL.absoluteString, placeholder: nil, {})
	}
	@objc func loadImage(atURL: URL?, placeholder: UIImage?) {
		guard let atURL = atURL else {return}
		loadImage(url: atURL.absoluteString, placeholder: placeholder, {})
	}
}
