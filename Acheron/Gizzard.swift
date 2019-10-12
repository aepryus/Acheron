//
//  Gizzard.swift
//  Acheron
//
//  Created by Joe Charlier on 10/2/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import Foundation

public class Gizzard {
	public var pebbles: [Pebble] = []	
	let queue: DispatchQueue = DispatchQueue(label: "gizzard")

	public let startPebble: Pebble = Pebble { (complete: (Bool)->()) in
		print(" == [ Gizzard Start Pebble ]\n")
		complete(true)
	}
	public let stopPebble: Pebble = Pebble { (complete: (Bool)->()) in
		print(" == [ Gizzard Stop Pebble ]\n")
		complete(true)
	}
	
	public init() {
		
	}
	
	func complete(pebble: Pebble) {
		queue.async {
			if pebble.state == .complete {
				pebble.downstream.forEach {$0.attemptToStart(self)}
			} else if pebble.state == .completeElse {
				pebble.elseDownstream.forEach {$0.attemptToStart(self)}
			}
		}
	}
	public func start() {
		queue.sync { [unowned self] in
			startPebble.attemptToStart(self)
		}
	}
}
