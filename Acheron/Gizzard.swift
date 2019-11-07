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
	let queue: DispatchQueue = DispatchQueue(label: "gizzard")
	private var tasks: [()->()] = []
	private var completed: Bool = false

	public init() {}

	private var complete: Bool {pebbles.first(where: {$0.state == .running}) == nil}
	private func checkIfComplete() {
		guard complete else {return}

		print("\n == [ Gizzard Complete ]\n")
		print("\t Successful Pebbles ===========")
		for pebble in pebbles.filter({$0.state == .success}) {
			print("\t\t - \(pebble.name)")
		}
		print("\n\t Exceptional Pebbles ===========")
		for pebble in pebbles.filter({$0.state == .exception}) {
			print("\t\t - \(pebble.name)")
		}
		print("\n\t Skipped Pebbles ===========")
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
			print(" == [ Gizzard Starting ]")
			self.iterate()
		}
	}
}
