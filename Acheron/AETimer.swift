//
//  AETimer.swift
//  Acheron
//
//  Created by Joe Charlier on 8/27/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import Foundation

public class AETimer {
	private let timer: DispatchSourceTimer = DispatchSource.makeTimerSource()
	
	public init() {}
	deinit {
		if !running { timer.resume() }
	}
	
	public var interval: Double = 1.0/60 {
		didSet { timer.schedule(deadline: .now(), repeating: interval) }
	}
	
	private(set) var running: Bool = false
	private var semaphore = DispatchSemaphore(value: 1)
	
	public func configure (interval: Double, _ closure: @escaping()->()) {
		timer.setEventHandler { [unowned self] in
			self.semaphore.wait()
			closure()
			self.semaphore.signal()
		}
		self.interval = interval
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
