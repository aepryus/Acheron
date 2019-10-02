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

class Pebble {
	enum State {
		case pending, running, complete
	}

	let payload: (_ complete: ()->())->()
	var state: Pebble.State = .pending
	private var upstream: WeakSet<Pebble> = []
	private var downstream: WeakSet<Pebble> = []
	weak var listener: PebbleListener? = nil
	
	init(_ payload: @escaping (_ complete: ()->())->()) {
		self.payload = payload
	}
}
