//
//  WeakSet.swift
//  Acheron
//
//  Created by Joe Charlier on 4/14/18.
//  Copyright © 2018 Aepryus Software. All rights reserved.
//

import Foundation

public class WeakSet<T: AnyObject>: Sequence, ExpressibleByArrayLiteral, CustomStringConvertible, CustomDebugStringConvertible {
	
	private var objects = NSHashTable<T>.weakObjects()
	
	public init(_ objects: [T]) {
		for object in objects {
			insert(object)
		}
	}
	
	public convenience required init(arrayLiteral elements: T...) {
		self.init(elements)
	}
	
	public var allObjects: [T] {
		return objects.allObjects
	}
	
	public var count: Int {
		return objects.count
	}
	
	public func contains(_ object: T) -> Bool {
		return objects.contains(object)
	}
	
	public func insert(_ object: T) {
		objects.add(object)
	}
	
	public func union(_ other: WeakSet<T>) -> WeakSet<T> {
		let result = WeakSet<T>()
		result.objects.union(self.objects)
		result.objects.union(other.objects)
		return result
	}
	public func formUnion(_ other: WeakSet<T>) {
		objects.union(other.objects)
	}
	public func formIntersection(_ other: WeakSet<T>) {
		objects.intersect(other.objects)
	}
	public func subtracting(_ other: WeakSet<T>) -> WeakSet<T> {
		let result = WeakSet<T>()
		result.objects.union(self.objects)
		for object in other.objects.allObjects {
			result.objects.remove(object)
		}
		return result
	}
	
	public func remove(_ object: T) {
		objects.remove(object)
	}
	public func removeAll() {
		objects.removeAllObjects()
	}
	
	public func makeIterator() -> AnyIterator<T> {
		let iterator = objects.objectEnumerator()
		return AnyIterator {
			return iterator.nextObject() as? T
		}
	}
	
	public var description: String {
		return objects.description
	}
	
	public var debugDescription: String {
		return objects.debugDescription
	}
	
	public static func != (lhs: WeakSet<T>, rhs: WeakSet<T>) -> Bool {
		return !lhs.objects.isEqual(to: rhs.objects)
	}
}
