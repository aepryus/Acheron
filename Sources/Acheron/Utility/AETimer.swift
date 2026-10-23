//
//  AETimer.swift
//  Acheron
//
//  Created by Joe Charlier on 8/27/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import Foundation

public class AETimer {
    private let timer: DispatchSourceTimer = DispatchSource.makeTimerSource(queue: .main)
    
    public init() {}
    deinit { if !running { timer.resume() } }
    
    public var interval: Double = 1.0/60 {
        didSet {
            guard interval != oldValue else { return }
            // the next tick keeps its place, an interval after the last — set now, every change
            // fired a tick at once, and a slider being dragged ran the timer fast
            timer.schedule(deadline: max(lastFire + interval, .now()), repeating: interval)
        }
    }
    private var lastFire: DispatchTime = .now()
    
    private(set) var running: Bool = false
    private var semaphore = DispatchSemaphore(value: 1)
    
    public func configure (interval: Double, _ closure: @escaping()->()) {
        timer.setEventHandler { [unowned self] in
            self.semaphore.wait()
            self.lastFire = .now()
            closure()
            self.semaphore.signal()
        }
        self.interval = interval
        timer.schedule(deadline: .now(), repeating: interval)
    }
    
    public func start() {
        guard !running else { return }
        running = true
        timer.resume()
    }
    public func stop() {
        guard running else { return }
        running = false
        semaphore.wait()
        timer.suspend()
        semaphore.signal()
    }
    public func reschedule() {
        timer.schedule(deadline: .now()+interval/2, repeating: interval)
    }
}
