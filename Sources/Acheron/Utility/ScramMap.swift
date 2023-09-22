//
//  ScramMap.swift
//  Acheron
//
//  Created by Joe Charlier on 9/12/23.
//  Copyright © 2023 Aepryus Software. All rights reserved.
//

import Foundation

protocol Scramble<Key> {
    associatedtype Key
    var complete: Bool { get }
    var progress: Bool { get }
    init(_: Key)
}

class ScramMap<T:Hashable, U:Scramble<T>> {
    let label: String
    let report: Bool

    let onScrape: (T,U)->()
    let onProgress: (T)->()
    
    let serial: DispatchQueue
    let concurrent: DispatchQueue
    
    var requestedKeys: Set<T> = Set()
    var completedKeys: Set<T> = Set()
    private var cache: [T:U] = [:]
    private var working: Bool = false
    
    init(label: String, report: Bool = false, _ onScrape: @escaping (T,U)->(), onProgress: @escaping (T)->()) {
        self.label = label
        self.report = report
        self.onScrape = onScrape
        self.onProgress = onProgress
        
        serial = DispatchQueue(label: "\(label).automaton.serial")
        concurrent = DispatchQueue(label: "\(label).automaton.concurrent", attributes: .concurrent)
    }
    
    subscript(key: T) -> U {
        set { serial.sync { cache[key] = newValue } }
        get { serial.sync {
            if let value = cache[key] { return value }
            cache[key] = U(key)
            return cache[key]!
        } }
    }
    
    private func handleRequests() {
        serial.async {
            self.working = true
            let keys: [T] = Array(self.requestedKeys)
            guard keys.count > 0 else {
                if self.report { print("[ \(self.label) ] concurrent completed") }
                self.working = false
                return
            }
            let group: DispatchGroup = DispatchGroup()
            keys.forEach { (key: T) in
                if self.report { print("[ \(self.label) ] request [ \(key) ]") }
                group.enter()
                self.concurrent.async {
                    let value: U = self[key]
                    self.onScrape(key, value)
                    self.serial.async {
                        if value.complete { self.completedKeys.insert(key) }
                        self.requestedKeys.remove(key)
                        if value.progress { self.onProgress(key) }
                        group.leave()
                    }
                }
            }
            group.notify(queue: self.serial) { self.handleRequests() }
        }
    }
    func queue(keys: [T]) {
        guard keys.count > 0 else { return }
        serial.async {
            let newKeys: Set<T> = Set(keys).subtracting(self.completedKeys).subtracting(self.requestedKeys)
            guard newKeys.count > 0 else { return }
            let restart: Bool = !newKeys.isEmpty && self.requestedKeys.isEmpty
            self.requestedKeys.formUnion(newKeys)
            if restart {
                if self.report { print("[ \(self.label) ] concurrent starting") }
                self.handleRequests()
            }
        }
    }
}
