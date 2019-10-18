//
//  Gizzard.swift
//  Acheron
//
//  Created by Joe Charlier on 10/2/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import Foundation

public class Gizzard {
	private var pebbles: [Pebble] = []
	private let queue: DispatchQueue = DispatchQueue(label: "gizzard")

	public let startPebble: Pebble = Pebble(name: "Gizzard Start") { (complete: (Bool)->()) in
		complete(true)
	}
	public let stopPebble: Pebble = Pebble(name: "Gizzard Stop") { (complete: (Bool)->()) in
		complete(true)
	}
	
	public init() {
		startPebble.ready = {true}
		stopPebble.ready = {true}
		pebbles.append(startPebble)
		pebbles.append(stopPebble)
	}
	
	func complete(pebble: Pebble) {
		queue.async {
			self.pebbles.forEach {$0.attemptToStart(self)}
		}
	}
	
	public func pebble(name: String, _ payload: @escaping (_ complete: @escaping (Bool)->())->()) -> Pebble {
		let pebble = Pebble(name: name, payload)
		pebbles.append(pebble)
		return pebble
	}
	
	public func start() {
		queue.async {
			self.startPebble.attemptToStart(self)
		}
	}
}
