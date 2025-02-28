//
//  Profiler.swift
//  Acheron
//
//  Created by Joe Charlier on 9/14/22.
//  Copyright © 2022 Aepryus Software. All rights reserved.
//

import Foundation

private class DoubleMap {
    private var map: [String:Double] = [:]
    
    func put(_ key: String, x: Double) { map[key] = x }
    func get(_ key: String) -> Double { map[key] ?? 0 }
}

private class TallyMap {
    var map: [String:Double] = [:]
    
    @discardableResult
    func increment(_ key: String) -> Double {
        map[key] = (map[key] ?? 0) + 1
        return map[key]!
    }

    @discardableResult
    func increment( _ key: String, x: Double) -> Double {
        map[key] = (map[key] ?? 0) + x
        return map[key]!
    }
    
    func getTally(_ key: String) -> Double { map[key] ?? 0 }
}

public class Profiler {
    public static var profiler: Profiler = Profiler()

    private let stopwatches: DoubleMap = DoubleMap()
    private let timekeeper: TallyMap = TallyMap()
    private let calls: TallyMap = TallyMap()
    
    private func start(_ key: String) {
        stopwatches.put(key, x: Date.now.timeIntervalSince1970)
        calls.increment(key)
    }
    private func stop(_ key: String) {
        timekeeper.increment(key, x: Date.now.timeIntervalSince1970 - stopwatches.get(key))
    }
    private func getTime(_ key: String) -> Double {
        timekeeper.getTally(key)
    }
    
//    private func print() -> String {
//        var sb: String = ""
//        sb += "\nKey\t\tCalls\tPer\n"
//        timekeeper.map.keys.sorted().forEach { (key: String) in
//            let per: Double = timekeeper.getTally(key) / calls.getTally(key)
//            sb += "\(key)\t\(calls.getTally(key))\t\(per)\n"
//        }
//        return sb
//    }
    private func print() -> String {
       let headers = ["Key", "Calls", "Per"]
       
       let keyWidth = max(headers[0].count, timekeeper.map.keys.map { $0.count }.max() ?? 0)
       let callsWidth = max(headers[1].count, timekeeper.map.keys.map { String(format: "%.0f", calls.getTally($0)).count }.max() ?? 0)
       
       var sb = "\n"
       sb += "\(headers[0].padding(toLength: keyWidth, withPad: " ", startingAt: 0))  " +
             "\(headers[1].padding(toLength: callsWidth, withPad: " ", startingAt: 0))  " +
             "\(headers[2])\n"
       
       timekeeper.map.keys.sorted().forEach { key in
           let callCount = calls.getTally(key)
           let per = timekeeper.getTally(key) / callCount
           sb += "\(key.padding(toLength: keyWidth, withPad: " ", startingAt: 0))  " +
                 "\(String(format: "%\(callsWidth).0f", callCount))  " +
                 "\(String(format: "%.3f", per))\n"
       }
       
       return sb
    }
    
    public static func reset() { Profiler.profiler = Profiler() }
    public static func start(_ key: String) { profiler.start(key) }
    public static func stop(_ key: String) { profiler.stop(key) }
    public static func getTime(_ key: String) -> Double { profiler.getTime(key) }
    public static func print() -> String { profiler.print() }
}
