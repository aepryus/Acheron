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

	public let startPebble: Pebble = Pebble { (complete: (Bool)->()) in
		print(" == [ Gizzard Start Pebble ]\n")
		complete(true)
	}
	public let stopPebble: Pebble = Pebble { (complete: (Bool)->()) in
		print(" == [ Gizzard Stop Pebble ]\n")
		complete(true)
	}
	
	public init() {
		pebbles.append(startPebble)
		pebbles.append(stopPebble)
	}
	
	func complete(pebble: Pebble) {
		queue.async {
			self.pebbles.forEach {$0.attemptToStart(self)}
		}
	}
	
	public func pebble(_ payload: @escaping (_ complete: @escaping (Bool)->())->()) -> Pebble {
		let pebble = Pebble(payload)
		pebbles.append(pebble)
		return pebble
	}
	
	public func start() {
		queue.async { [unowned self] in
			self.startPebble.attemptToStart(self)
		}
	}
}
