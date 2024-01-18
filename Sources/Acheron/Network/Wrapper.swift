//
//  Wrapper.swift
//  Acheron
//
//  Created by Joe Charlier on 1/18/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

import Foundation

open class Wrapper {
    public enum Method: CaseIterable {
        case get, post
        var token: String { "\(self)".uppercased() }
    }
    let baseURL: String
    
    init(baseURL: String) {
        self.baseURL = baseURL
    }

    public func request(path: String, method: Method, params: [String:String]? = nil, success: @escaping ([String:Any])->(), failure: @escaping ()->()) {
        var urlString: String = "\(baseURL)\(path)"
        
        if method == .get, let params { params.enumerated().forEach { urlString += "\($0.offset == 0 ? "?":"&")\($0.element.key)=\($0.element.value)" } }
        
        let url: URL = URL(string: urlString)!
        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = method.token
        
        if method == .post, let params { request.httpBody = params.toJSON().data(using: .utf8) }
        
        let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            guard error == nil else {
                print("error: \(error!)")
                failure()
                return
            }

            guard let data else { failure(); return }
            
            if let response = response as? HTTPURLResponse, !(200...299).contains(response.statusCode) {
                print("\n[ \(path) : \(response.statusCode) ] ===================================================")
                if let headers = request.allHTTPHeaderFields { print("headers ========================\n\(headers.toJSON())\n") }
                if let params = params { print("params =========================\n\(params.toJSON())\n") }
                if let message = String(data: data, encoding: .utf8) { print("message =========================\n\(message)\n") }
                failure()
                return
            }
        
            if let result = String(data: data, encoding: .utf8) { success(result.toAttributes()) }
            else { failure() }
        }
        task.resume()
    }
}
