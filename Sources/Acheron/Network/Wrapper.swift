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
    open var session: URLSession { URLSession.shared }
    
    public init(baseURL: String) {
        self.baseURL = baseURL
    }

    public func request(path: String, method: Method, params: [String:Any]? = nil, success: @escaping ([String:Any])->(), failure: @escaping (String)->()) {
        var urlString: String = "\(baseURL)\(path)"
        
        if method == .get, let params {
            var components: URLComponents = URLComponents(string: urlString)!
            components.queryItems = params.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
            urlString = components.url!.absoluteString
        }
        
        let url: URL = URL(string: urlString)!
        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = method.token
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if method == .post, let params { request.httpBody = params.toJSON().data(using: .utf8) }
        
        let task = session.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            if let error {
                failure(error.localizedDescription)
                return
            }

            guard let data else { failure("no data"); return }
            
            if let response = response as? HTTPURLResponse, !(200...299).contains(response.statusCode) {
                let message = String(data: data, encoding: .utf8) ?? ""
                failure("HTTP \(response.statusCode): \(message.prefix(200))")
                return
            }
        
            if let result = String(data: data, encoding: .utf8) { success(result.toAttributes()) }
            else { failure("decode failed") }
        }
        task.resume()
    }
}
