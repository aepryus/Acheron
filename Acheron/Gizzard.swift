//
//  Gizzard.swift
//  Acheron
//
//  Created by Joe Charlier on 10/2/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import Foundation

class Gizzard {
	let pebbles: [Pebble]
	let queue: DispatchQueue = DispatchQueue(label: "gizzard")
	
	init(pebbles: [Pebble]) {
		self.pebbles = pebbles
	}
	
	func complete(pebble: Pebble) {
		queue.async {
			pebble.downstream.forEach {$0.attemptToStart(self)}
		}
	}
	func start() {
		queue.async { [unowned self] in
			self.pebbles.forEach {$0.attemptToStart(self)}
		}
	}
}
