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
	public var ready: (()->(Bool)) = {false}
	private(set) var state: Pebble.State = .pending
	
	public var succeeded: Bool {return state == .succeeded}
	public var failed: Bool {return state == .failed}
	public var completed: Bool {return state == .succeeded || state == .failed}
	
	init(name: String, _ payload: @escaping (_ complete: @escaping (Bool)->())->()) {
		self.name = name
		self.payload = payload
	}
	
	func attemptToStart(_ gizzard: Pond) {
		guard state == .pending else {return}
		guard ready() else {return}
		
		state = .running
		DispatchQueue.main.async {
			print("\n == [ \(self.name) ]")
			self.payload { (success: Bool) in
				gizzard.queue.async {
					self.state = success ? .succeeded : .failed
					gizzard.iterate()
				}
			}
		}
	}
	func reset() {
		state = .pending
	}
}
