//
//  SafeSet.swift
//  Acheron
//
//  Created by Joe Charlier on 10/29/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import Foundation

public class SafeSet<T: Hashable>: Sequence, ExpressibleByArrayLiteral {
	private var set: Set<T> = Set<T>()
	private let queue: DispatchQueue = DispatchQueue(label: "SafeSet")

	public init(_ objects: [T]) {
		for object in objects {
			insert(object)
		}
	}
	public convenience required init(arrayLiteral elements: T...) {
		self.init(elements)
	}
	
	public var count: Int {
		return queue.sync {set.count}
	}
	
	public func makeIterator() -> Set<T>.Iterator {
		return queue.sync {set.makeIterator()}
	}
	@discardableResult
	public func insert(_ object: T) -> (Bool, T) {
		return queue.sync {set.insert(object)}
	}
	public func removeAll() {
		queue.sync {set.removeAll()}
	}
}
