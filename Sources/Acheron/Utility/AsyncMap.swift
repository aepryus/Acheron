//
//  ScramMap.swift
//  Acheron
//
//  Created by Joe Charlier on 7/23/23.
//  Copyright © 2023 Aepryus Software. All rights reserved.
//

import Foundation

public class AsyncMap<T:Hashable, U> {
    let label: String
    let report: Bool
    let worker: (T)->(U?)
    let complete: ((T)->())?
    
    let serial: DispatchQueue
    let concurrent: DispatchQueue
    
    var requestedKeys: Set<T> = Set()
    var completedKeys: Set<T> = Set()
    private var cache: [T:U] = [:]
    private var working: Bool = false
    private var needsWipe: Bool = false
    
    init(label: String, report: Bool = false, _ worker: @escaping (T)->(U?), complete: ((T)->())? = nil) {
        self.label = label
        self.report = report
        self.worker = worker
        self.complete = complete
        
        serial = DispatchQueue(label: "\(label).automaton.serial")
        concurrent = DispatchQueue(label: "\(label).automaton.concurrent", attributes: .concurrent)
    }
    
    subscript(key: T) -> U? {
        set { serial.sync { cache[key] = newValue } }
        get { serial.sync { cache[key] } }
    }
    
    private func startWorking() {
        serial.async {
            self.working = true
            let keys: [T] = Array(self.requestedKeys)
            guard keys.count > 0 else {
                if self.report { print("[ \(self.label) ] concurrent completed") }
                if self.needsWipe {
                    self.wipe()
                    self.needsWipe = false
                }
                self.working = false
                return
            }
            let group: DispatchGroup = DispatchGroup()
            keys.forEach { (key: T) in
                if self.report { print("[ \(self.label) ] request [ \(key) ]") }
                group.enter()
                self.concurrent.async {
                    let result: U? = self.worker(key)
                    self.serial.async {
                        if let result {
                            if self.report { print("[ \(self.label) ] complete [ \(key) ]") }
                            self.cache[key] = result
                        }
                        self.completedKeys.insert(key)
                        self.requestedKeys.remove(key)
                        group.leave()
                    }
                }
            }
            group.notify(queue: self.serial) {
                keys.forEach { self.complete?($0) }
                self.startWorking()
            }
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
                self.startWorking()
            }
        }
    }
    
    func wipe() {
        if self.report { print("[ \(self.label) ] wiped") }
        self.requestedKeys.removeAll()
        self.completedKeys.removeAll()
        self.cache.removeAll()
    }
    func scheduleWipe() {
        serial.async {
            if self.working { self.needsWipe = true }
            else { self.wipe() }
        }
    }
}
