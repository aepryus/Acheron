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
	private static var listenerArrays: [String:[(UIImage)->()]] = [:]

	public static func loadImage(url: String, alreadyLoaded: @escaping (UIImage)->(), willLoad: @escaping ()->(), finishedLoading: @escaping (UIImage)->()) {
		let image: UIImage? = UIImage.images[url]
		
		guard image == nil else { alreadyLoaded(image!);return }
		
		willLoad()
		
		var needsRequest: Bool = false
		if UIImage.listenerArrays[url] == nil {
			needsRequest = true
			UIImage.listenerArrays[url] = []
		}
		UIImage.listenerArrays[url]!.append(finishedLoading)
		
		guard needsRequest else { return }
		
		guard let URL = URL(string: url) else { return }
		let request = URLRequest(url: URL)

		URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
			guard let data = data else { return }
			guard let image: UIImage = UIImage(data: data) else { return }
			DispatchQueue.main.async {
				UIImage.images[url] = image
				let listenerArray = UIImage.listenerArrays.removeValue(forKey: url)!
				listenerArray.forEach { $0(image) }
			}
		}.resume()
	}
	public static func loadImage(url: String, _ complete: @escaping (UIImage)->()) {
		UIImage.loadImage(url: url, alreadyLoaded: complete, willLoad: {}, finishedLoading: complete)
	}
}
