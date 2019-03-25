//
//  UIImageView+Acheron.swift
//  Acheron
//
//  Created by Joe Charlier on 3/25/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import UIKit

extension UIImageView {
	static var images: [String:UIImage] = [:]
	static var imageViewSets: [String:Set<UIImageView>] = [:]
	static var urlLookup: [UInt:String] = [:]
	
	var identifier: UInt {
		return UInt(bitPattern: ObjectIdentifier(self))
	}
	
	func loadImage(url: String,_ complete: @escaping ()->()) {
		self.image = UIImageView.images[url]
		guard self.image == nil else {return}

		let oldURL: String? = UIImageView.urlLookup[identifier]
		if let oldURL = oldURL, oldURL != url {
			UIImageView.imageViewSets[oldURL]!.remove(self)
		}
		UIImageView.urlLookup[identifier] = url

		var imageViews: Set<UIImageView>? = UIImageView.imageViewSets[url]
		if imageViews != nil {
			imageViews!.insert(self)
			return
		}
		imageViews = Set<UIImageView>([self])
		UIImageView.imageViewSets[url] = imageViews
		
		let request = URLRequest(url: URL(string: url)!)
		NSURLConnection.sendAsynchronousRequest(request, queue: OperationQueue.main) { (response: URLResponse?, data: Data?, error: Error?) in
			guard let data = data else {return}
			guard let image: UIImage = UIImage(data: data) else {return}
			UIImageView.images[url] = image
			let imageViewSet = UIImageView.imageViewSets.removeValue(forKey: url)!
			imageViewSet.forEach {$0.image = image}
			complete()
		}
		
	}
	func loadImage(url: String) {
		loadImage(url: url, {})
	}
}
