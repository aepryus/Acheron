//
//  Pebble.swift
//  Acheron
//
//  Created by Joe Charlier on 10/2/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import Foundation

protocol PebbleListener: class {
	func onComplete()
}

public class Pebble {
	enum State {
		case pending, running, success, exception
	}

	public var ready: (()->(Bool))? = nil
	let payload: (_ complete: @escaping (Bool)->())->()
	var state: Pebble.State = .pending
	
	public var succeeded: Bool {return state == .success}
	public var excepted: Bool {return state == .exception}
	public var completed: Bool {return state == .success || state == .exception}
	
	init(_ payload: @escaping (_ complete: @escaping (Bool)->())->()) {
		self.payload = payload
	}
	
	func attemptToStart(_ gizzard: Gizzard) {
		guard state == .pending else {return}
		guard ready == nil || (ready!() == true) else {return}
		
		state = .running
		DispatchQueue.main.async {
			self.payload { (success: Bool) in
				self.state = success ? .success : .exception
				gizzard.complete(pebble: self)
			}
		}
	}
}
