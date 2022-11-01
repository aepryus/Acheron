//
//  UIImage+Acheron.swift
//  Acheron
//
//  Created by Joe Charlier on 4/8/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

#if canImport(UIKit)

import UIKit

extension UIImage {
    private static var images: [String:UIImage] = [:]
    private static var listeners: [String:[(UIImage)->()]] = [:]

    public static func loadImage(url: String, alreadyLoaded: (UIImage)->(), willLoad: ()->(), finishedLoading: @escaping (UIImage)->()) {
        guard let URL: URL = URL(string: url) else { willLoad(); return }

        let image: UIImage? = UIImage.images[url]

        guard image == nil else { alreadyLoaded(image!); return }
        
        willLoad()

        if UIImage.listeners[url] == nil {
            UIImage.listeners[url] = [finishedLoading]
            URLSession.shared.dataTask(with: URLRequest(url: URL)) { (data: Data?, response: URLResponse?, error: Error?) in
                guard let data = data, let image: UIImage = UIImage(data: data) else { return }
                DispatchQueue.main.async {
                    UIImage.images[url] = image
                    let listeners: [(UIImage)->()] = UIImage.listeners.removeValue(forKey: url)!
                    listeners.forEach { $0(image) }
                }
            }.resume()

        } else { UIImage.listeners[url]!.append(finishedLoading) }
        
    }
    public static func loadImage(url: String, _ complete: @escaping (UIImage)->()) {
        UIImage.loadImage(url: url, alreadyLoaded: complete, willLoad: {}, finishedLoading: complete)
    }
    
    public var ratio: CGFloat { size.height / size.width }
}

#endif
