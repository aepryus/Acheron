//
//  Pebble.swift
//  Acheron
//
//  Created by Joe Charlier on 10/2/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import Foundation

public class Pebble: Identifiable, Comparable {
    public let id: UUID = UUID()
    public private(set) var name: String
    
    public private(set) var complete: Bool = false
    public private(set) var failed: Bool = false
    
    private var action: ((@escaping (Bool) -> ()) -> ())?
    public var ready: () -> Bool = { true }
    
    weak var pond: Pond?
    
    public init(name: String, action: ((@escaping (Bool) -> ()) -> ())? = nil) {
        self.name = name
        self.action = action
    }
    
    func execute() {
        guard !complete else { return }
        guard ready() else { return }
        if let action = action {
            action { success in
                self.complete = true
                self.failed = !success
                self.pond?.start()
            }
        } else {
            complete = true
            pond?.start()
        }
    }
    
    public static func ==(lhs: Pebble, rhs: Pebble) -> Bool { lhs.id == rhs.id }
    public static func <(lhs: Pebble, rhs: Pebble) -> Bool { lhs.name < rhs.name }
}

public func pebble(name: String, action: @escaping (@escaping (Bool) -> ()) -> ()) -> Pebble {
    return Pebble(name: name, action: action)
}
