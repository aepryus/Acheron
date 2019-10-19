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
		case pending, running, success, exception
	}

	let name: String
	let payload: (_ complete: @escaping (Bool)->())->()
	public var ready: (()->(Bool)) = {false}
	var state: Pebble.State = .pending
	
	public var succeeded: Bool {return state == .success}
	public var excepted: Bool {return state == .exception}
	public var completed: Bool {return state == .success || state == .exception}
	
	init(name: String, _ payload: @escaping (_ complete: @escaping (Bool)->())->()) {
		self.name = name
		self.payload = payload
	}
	
	func attemptToStart(_ gizzard: Gizzard) {
		guard state == .pending else {return}
		guard ready() == true else {return}
		
		state = .running
		DispatchQueue.main.async {
			print(" == [ \(self.name) ]\n")
			self.payload { (success: Bool) in
				self.state = success ? .success : .exception
				gizzard.complete(pebble: self)
			}
		}
	}
}
