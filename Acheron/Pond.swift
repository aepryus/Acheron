//
//  Pond.swift
//  Acheron
//
//  Created by Joe Charlier on 10/2/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import Foundation

public class Pond {
	private var pebbles: [Pebble] = []
	let queue: DispatchQueue = DispatchQueue(label: "pond")
	private var tasks: [()->()] = []
	private var completed: Bool = false

	public init() {}

	public var complete: Bool {pebbles.first(where: {$0.state == .running}) == nil}
	public var started: Bool {pebbles.first(where: {$0.state != .pending}) != nil}
	private func checkIfComplete() {
		guard complete else {return}

		print("\n == [ Pond Complete ]\n")
		print("\t Succeeded Pebbles ===========")
		for pebble in pebbles.filter({$0.state == .succeeded}) {
			print("\t\t - \(pebble.name)")
		}
		print("\n\t Failed Pebbles ==============")
		for pebble in pebbles.filter({$0.state == .failed}) {
			print("\t\t - \(pebble.name)")
		}
		print("\n\t Skipped Pebbles =============")
		for pebble in pebbles.filter({$0.state == .pending}) {
			print("\t\t - \(pebble.name)")
		}
		print("\n =======================\n")
		
		DispatchQueue.main.async {
			self.completed = true
			self.tasks.forEach { (task: @escaping () -> ()) in
				task()
			}
		}
	}
	
	func iterate() {
		pebbles.forEach {$0.attemptToStart(self)}
		checkIfComplete()
	}
	
	public func pebble(name: String, _ payload: @escaping (_ complete: @escaping (Bool)->())->()) -> Pebble {
		let pebble = Pebble(name: name, payload)
		pebbles.append(pebble)
		return pebble
	}
	public func addCompletionTask(_ task: @escaping ()->()) {
		dispatchPrecondition(condition: .onQueue(DispatchQueue.main))
		if completed {
			task()
		} else {
			tasks.append(task)
		}
	}

	public func start() {
		queue.async {
			print(" == [ Pond Starting ]")
			self.iterate()
		}
	}
	public func reset() {
		queue.sync {
			self.pebbles.forEach {$0.reset()}
		}
	}
}
