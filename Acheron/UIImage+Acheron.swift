//
//  UIImage+Acheron.swift
//  Acheron
//
//  Created by Joe Charlier on 4/8/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import UIKit

extension UIImage {
	private static var images: [String:UIImage] = [:]
	private static var listeners: [String:[(UIImage)->()]] = [:]

	public static func loadImage(url: String, alreadyLoaded: (UIImage)->(), willLoad: ()->(), finishedLoading: @escaping (UIImage)->()) {
		let image: UIImage? = UIImage.images[url]
		
		guard image == nil else { alreadyLoaded(image!); return }
		
		willLoad()
		
		var needsRequest: Bool = false
		if UIImage.listeners[url] == nil {
			needsRequest = true
			UIImage.listeners[url] = []
		}
		UIImage.listeners[url]!.append(finishedLoading)
		
		guard needsRequest, let URL = URL(string: url) else { return }
		
		let request = URLRequest(url: URL)

		URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
			guard let data = data, let image: UIImage = UIImage(data: data) else { return }
			DispatchQueue.main.async {
				UIImage.images[url] = image
				let listeners: [(UIImage)->()] = UIImage.listeners.removeValue(forKey: url)!
				listeners.forEach { $0(image) }
			}
		}.resume()
	}
	public static func loadImage(url: String, _ complete: @escaping (UIImage)->()) {
		UIImage.loadImage(url: url, alreadyLoaded: complete, willLoad: {}, finishedLoading: complete)
	}
}
