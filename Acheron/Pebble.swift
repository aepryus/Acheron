//
//  Pebble.swift
//  Acheron
//
//  Created by Joe Charlier on 10/2/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import Foundation

public class Pebble {
	enum State {
		case pending, running, succeeded, failed
	}

	let name: String
	private let payload: (_ complete: @escaping (Bool)->())->()
	public var ready: (()->(Bool)) = { false }
	private(set) var state: Pebble.State = .pending
	
	public var succeeded: Bool { state == .succeeded }
	public var failed: Bool { state == .failed }
	public var completed: Bool { state == .succeeded || state == .failed }
	
	init(name: String, _ payload: @escaping (_ complete: @escaping (Bool)->())->()) {
		self.name = name
		self.payload = payload
	}
	
	func attemptToStart(_ pond: Pond) {
		guard state == .pending, ready() else { return }
		
		state = .running
		DispatchQueue.main.async {
			print("\n == [ \(self.name) ]")
			self.payload { (success: Bool) in
				pond.queue.async {
					self.state = success ? .succeeded : .failed
					pond.iterate()
				}
			}
		}
	}
	func reset() {
		state = .pending
	}
}
