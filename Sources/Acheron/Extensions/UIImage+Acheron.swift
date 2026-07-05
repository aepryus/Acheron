//
//  UIImage+Acheron.swift
//  Acheron
//
//  Created by Joe Charlier on 4/8/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

#if canImport(UIKit)

import CryptoKit
import UIKit

extension UIImage {
    private static var images: [String:UIImage] = [:]
    private static var listeners: [String:[(UIImage)->()]] = [:]

    private static let cacheDirectory: URL = {
        let url: URL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("acheron-images", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }()
    private static func cacheFile(for url: String) -> URL {
        let digest: String = Insecure.MD5.hash(data: Data(url.utf8)).map { String(format: "%02x", $0) }.joined()
        return cacheDirectory.appendingPathComponent(digest)
    }

    public static func loadImage(url: String, alreadyLoaded: (UIImage)->(), willLoad: ()->(), finishedLoading: @escaping (UIImage)->()) {
        guard let URL: URL = URL(string: url) else { willLoad(); return }

        let image: UIImage? = UIImage.images[url]

        guard image == nil else { alreadyLoaded(image!); return }
        
        willLoad()

        if UIImage.listeners[url] == nil {
            UIImage.listeners[url] = [finishedLoading]
            let cacheFile: URL = UIImage.cacheFile(for: url)
            DispatchQueue.global(qos: .userInitiated).async {
                if let data = try? Data(contentsOf: cacheFile), let image: UIImage = UIImage(data: data) {
                    DispatchQueue.main.async {
                        UIImage.images[url] = image
                        UIImage.listeners.removeValue(forKey: url)?.forEach { $0(image) }
                    }
                    return
                }
                URLSession.shared.dataTask(with: URLRequest(url: URL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 15)) { (data: Data?, response: URLResponse?, error: Error?) in
                    guard let data = data, let image: UIImage = UIImage(data: data) else {
                        DispatchQueue.main.async { UIImage.listeners.removeValue(forKey: url) }    // failed; allow retry
                        return
                    }
                    try? data.write(to: cacheFile)
                    DispatchQueue.main.async {
                        UIImage.images[url] = image
                        UIImage.listeners.removeValue(forKey: url)?.forEach { $0(image) }
                    }
                }.resume()
            }

        } else { UIImage.listeners[url]!.append(finishedLoading) }
        
    }
    public static func loadImage(url: String, _ complete: @escaping (UIImage)->()) {
        UIImage.loadImage(url: url, alreadyLoaded: complete, willLoad: {}, finishedLoading: complete)
    }
    
    public var ratio: CGFloat { size.height / size.width }
}

#endif
