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
	
	public init() {
		startPebble.ready = {true}
		pebbles.append(startPebble)
	}
	
	
	private func checkIfComplete() {
		if pebbles.first(where: {$0.state == .running}) == nil {
			print(" == [ Gizzard Complete ]\n")
			
			print("\t Successful Pebbles ===========")
			for pebble in pebbles.filter({$0.state == .success}) {
				print("\t\t - \(pebble.name)")
			}
			
			print("\t Exceptional Pebbles ===========")
			for pebble in pebbles.filter({$0.state == .exception}) {
				print("\t\t - \(pebble.name)")
			}

			print("\t Skipped Pebbles ===========")
			for pebble in pebbles.filter({$0.state == .pending}) {
				print("\t\t - \(pebble.name)")
			}
		}
	}
	
	func complete(pebble: Pebble) {
		queue.async {
			self.pebbles.forEach {$0.attemptToStart(self)}
			self.checkIfComplete()
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
