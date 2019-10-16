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
		case pending, running, complete, completeElse
	}

	let payload: (_ complete: @escaping (Bool)->())->()
	var state: Pebble.State = .pending
	var downstream: WeakSet<Pebble> = []
	var necessary: WeakSet<Pebble> = []
	var sufficient: WeakSet<Pebble> = []
	var elseDownstream: WeakSet<Pebble> = []
	var elseNecessary: WeakSet<Pebble> = []
	var elseSufficient: WeakSet<Pebble> = []
//	weak var listener: PebbleListener? = nil
	
	public init(_ payload: @escaping (_ complete: @escaping (Bool)->())->()) {
		self.payload = payload
	}
	
	public func isNeccessary(for pebble: Pebble) {
		downstream.insert(pebble)
		pebble.necessary.insert(self)
	}
	public func isSufficient(for pebble: Pebble) {
		downstream.insert(pebble)
		pebble.sufficient.insert(self)
	}
	public func elseIsNeccessary(for pebble: Pebble) {
		elseDownstream.insert(pebble)
		pebble.elseNecessary.insert(self)
	}
	public func elseIsSufficient(for pebble: Pebble) {
		elseDownstream.insert(pebble)
		pebble.elseSufficient.insert(self)
	}

//	public func attach(pebble: Pebble) {
//		downstream.insert(pebble)
//		pebble.upstream.insert(self)
//	}
	
	func attemptToStart(_ gizzard: Gizzard) {
		guard state == .pending else {return}
		guard necessary.first(where: {$0.state != .complete}) == nil else {return}
		guard elseNecessary.first(where: {$0.state != .completeElse}) == nil else {return}
		guard sufficient.count == 0 || sufficient.first(where: {$0.state == .complete}) != nil else {return}
		guard elseSufficient.count == 0 || elseSufficient.first(where: {$0.state == .completeElse}) != nil else {return}

		state = .running
		self.payload { (success: Bool) in
			self.state = success ? .complete : .completeElse
			gizzard.complete(pebble: self)
		}
	}
}
