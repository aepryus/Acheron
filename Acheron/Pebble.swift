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
		case pending, running, complete
	}

	let payload: (_ complete: ()->())->()
	var state: Pebble.State = .pending
	private var upstream: WeakSet<Pebble> = []
	var downstream: WeakSet<Pebble> = []
	weak var listener: PebbleListener? = nil
	
	public init(_ payload: @escaping (_ complete: ()->())->()) {
		self.payload = payload
	}
	
	public func attach(pebble: Pebble) {
		downstream.insert(pebble)
		pebble.upstream.insert(self)
	}
	
	func attemptToStart(_ gizzard: Gizzard) {
		guard state == .pending else {return}
		guard upstream.first(where: {$0.state != .complete}) == nil else {return}

		state = .running
		payload {
			state = .complete
			gizzard.complete(pebble: self)
		}
	}
}
