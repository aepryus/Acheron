//
//  Pond.swift
//  Acheron
//
//  Created by Joe Charlier on 10/2/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import Foundation

open class Pond {
	private var pebbles: [Pebble] = []
	let queue: DispatchQueue = DispatchQueue(label: "pond")
	private var tasks: [()->()] = []
	private var completed: Bool = false

	public init() {}

	open func wirePebbles() {}

	public var complete: Bool { pebbles.first(where: {$0.state == .running}) == nil }
	public var started: Bool { pebbles.first(where: {$0.state != .pending}) != nil }
	private func checkIfComplete() {
		guard complete else { return }

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
		pebbles.forEach { $0.attemptToStart(self) }
		checkIfComplete()
	}
	
	public func pebble(name: String, failable: Bool = true, _ payload: @escaping (_ complete: @escaping (Bool)->())->()) -> Pebble {
		let pebble = Pebble(name: name, failable: failable, payload)
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
		queue.sync { self.pebbles.forEach { $0.reset() } }
	}

// Testing =========================================================================================
	public func resetTest() {
		pebbles.forEach { $0.testState = nil }
	}
	private func compare(should: [Pebble], actual: [Pebble]) -> Bool {
		var equivalent: Bool = true
		should.forEach { (a: Pebble) in
			if !actual.contains(where: {a === $0}) {
				print("\tpebble [\(a.name)] should appear, but does not")
				equivalent = false
			}
		}
		actual.forEach { (a: Pebble) in
			if !should.contains(where: {a === $0}) {
				print("\tpebble [\(a.name)] does appear, but shouldn't")
				equivalent = false
			}
		}
		return equivalent
	}
	public func test(shouldSucceed: [Pebble], shouldFail: [Pebble]) -> Bool {
		wirePebbles()
		reset()
		resetTest()
		shouldSucceed.forEach { $0.testState = .succeeded }
		shouldFail.forEach { $0.testState = .failed }
		let shouldSkip: [Pebble] = pebbles.filter { $0.testState == nil }
		var previous: Int = 0
		var current: Int = pebbles.filter({ $0.state == .pending }).count
		repeat {
			previous = current
			pebbles.forEach { $0.attemptToTest(self) }
			current = pebbles.filter({ $0.state == .pending }).count
		} while !complete || previous != current

		var succeeded: [Pebble] = []
		var failed: [Pebble] = []
		var skipped: [Pebble] = []

		pebbles.forEach {
			switch $0.state {
				case .succeeded:	succeeded.append($0)
				case .failed:		failed.append($0)
				case .pending:		skipped.append($0)
				case .running:		fatalError()
			}
		}

		var passed: Bool = true
		print("\nSucceeded Pebbles =========================")
		if !compare(should: shouldSucceed, actual: succeeded) { passed = false }
		print("Failed Pebbles ============================")
		if !compare(should: shouldFail, actual: failed) { passed = false }
		print("Skipped Pebbles ===========================")
		if !compare(should: shouldSkip, actual: skipped) { passed = false }
		return passed
	}
}
