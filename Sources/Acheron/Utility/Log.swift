//
//  Log.swift
//  Acheron
//
//  Created by Joe Charlier on 7/11/20.
//  Copyright © 2020 Aepryus Software. All rights reserved.
//

import Foundation

class Log {
    private static var url: URL? = nil
    
    static func setPath(_ path: String) {
        url = URL(fileURLWithPath: path)
        if !FileManager.default.fileExists(atPath: url!.path) {
            FileManager.default.createFile(atPath: url!.path, contents: nil, attributes: nil)
        }
    }
    
    static func print(_ string: String) {
        Swift.print(string)

        guard let url = url,
              let fileHandle = FileHandle(forWritingAtPath: url.path),
              let data: Data = "[\(Date().toISOFormattedString())] \(string)\n".data(using: .utf8)
            else { return }
        
        defer { fileHandle.closeFile() }

        fileHandle.seekToEndOfFile()
        fileHandle.write(data)
    }
}
