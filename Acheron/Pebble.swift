//
//  Pebble.swift
//  Acheron
//
//  Created by Joe Charlier on 10/2/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import Foundation

public class Pebble {
	public enum State {
		case pending, running, succeeded, failed
	}

	let name: String
	let failable: Bool
	private let payload: (_ complete: @escaping (Bool)->())->()
	public var ready: (()->(Bool)) = { false }
	private(set) var state: Pebble.State = .pending
	
	public var succeeded: Bool { state == .succeeded }
	public var failed: Bool { state == .failed }
	public var completed: Bool { state == .succeeded || state == .failed }
	public var skipped: Bool { state == .pending }

	init(name: String, failable: Bool, _ payload: @escaping (_ complete: @escaping (Bool)->())->()) {
		self.name = name
		self.failable = failable
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

// Testing =========================================================================================
	public var testState: Pebble.State? = nil {
		didSet { guard testState != .pending && testState != .running else { fatalError() } }
	}
	func attemptToTest(_ pond: Pond) {
		guard state == .pending, ready() else { return }

		guard failable else { state = .succeeded; return }

		guard let testState = testState else {
			print("ERROR: Pebble [\(name)] not provided a testState")
			fatalError()
		}

		state = testState
	}
}
