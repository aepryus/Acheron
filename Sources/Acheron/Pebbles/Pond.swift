//
//  Pond.swift
//  Acheron
//
//  Created by Joe Charlier on 10/2/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import Foundation

open class Pond {
    public private(set) var pebbles: [Pebble] = []
    
    private var semaphore = DispatchSemaphore(value: 1)
    private var complete: Bool { pebbles.filter{ !$0.complete }.count == 0 }
    private var failed: Bool { pebbles.filter{ $0.failed }.count > 0 }
    
    public init() {}
    
    public func addPebble(_ pebble: Pebble) {
        pebble.pond = self
        pebbles.append(pebble)
    }
    
    public func start(async: Bool = false) {
        semaphore.wait()
        defer { semaphore.signal() }
        guard !complete else { return }
        
        if async {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.pebbles.forEach { $0.execute() }
            }
        } else {
            pebbles.forEach { $0.execute() }
        }
    }
}
