//
//  WeakSet.swift
//  Acheron
//
//  Created by Joe Charlier on 4/14/18.
//  Copyright © 2018 Aepryus Software. All rights reserved.
//

#if !os(Linux)

import Foundation

public class WeakSet<T: AnyObject>: Sequence, ExpressibleByArrayLiteral, CustomStringConvertible, CustomDebugStringConvertible {
    
    private var objects: NSHashTable<T> = NSHashTable<T>.weakObjects()
    
    public init(_ objects: [T]) {
        objects.forEach { insert($0) }
    }
    public convenience required init(arrayLiteral elements: T...) {
        self.init(elements)
    }
    
    public var allObjects: [T] { objects.allObjects }
    
    public var count: Int { objects.count }
    
    public func contains(_ object: T) -> Bool { objects.contains(object) }
    
    public func insert(_ object: T) { objects.add(object) }
    
    public func union(_ other: WeakSet<T>) -> WeakSet<T> {
        let result = WeakSet<T>()
        result.objects.union(self.objects)
        result.objects.union(other.objects)
        return result
    }
    public func formUnion(_ other: WeakSet<T>) { objects.union(other.objects) }
    public func formIntersection(_ other: WeakSet<T>) { objects.intersect(other.objects) }
    public func subtracting(_ other: WeakSet<T>) -> WeakSet<T> {
        let result = WeakSet<T>()
        result.objects.union(self.objects)
        for object in other.objects.allObjects {
            result.objects.remove(object)
        }
        return result
    }
    
    public func remove(_ object: T) { objects.remove(object) }
    public func removeAll() { objects.removeAllObjects() }
    
    public func makeIterator() -> AnyIterator<T> {
        let iterator = objects.objectEnumerator()
        return AnyIterator {
            return iterator.nextObject() as? T
        }
    }
    
    public var description: String { objects.description }
    
    public var debugDescription: String { objects.debugDescription }
    
    public static func != (lhs: WeakSet<T>, rhs: WeakSet<T>) -> Bool { !lhs.objects.isEqual(to: rhs.objects) }
}

#else

import Foundation

// Foundation on Linux has no NSHashTable: weak boxes keyed by identity, pruned as they're read.
public class WeakSet<T: AnyObject>: Sequence, ExpressibleByArrayLiteral, CustomStringConvertible, CustomDebugStringConvertible {
    private struct Box { weak var object: T? }
    private var boxes: [ObjectIdentifier:Box] = [:]

    public init(_ objects: [T]) {
        objects.forEach { insert($0) }
    }
    public convenience required init(arrayLiteral elements: T...) {
        self.init(elements)
    }

    public var allObjects: [T] {
        boxes = boxes.filter { $0.value.object != nil }
        return boxes.values.compactMap { $0.object }
    }
    public var count: Int { allObjects.count }

    public func contains(_ object: T) -> Bool { boxes[ObjectIdentifier(object)]?.object != nil }

    public func insert(_ object: T) { boxes[ObjectIdentifier(object)] = Box(object: object) }

    public func union(_ other: WeakSet<T>) -> WeakSet<T> { WeakSet(allObjects + other.allObjects) }
    public func formUnion(_ other: WeakSet<T>) { other.allObjects.forEach { insert($0) } }
    public func formIntersection(_ other: WeakSet<T>) { allObjects.filter { !other.contains($0) }.forEach { remove($0) } }
    public func subtracting(_ other: WeakSet<T>) -> WeakSet<T> { WeakSet(allObjects.filter { !other.contains($0) }) }

    public func remove(_ object: T) { boxes[ObjectIdentifier(object)] = nil }
    public func removeAll() { boxes.removeAll() }

    public func makeIterator() -> AnyIterator<T> { AnyIterator(allObjects.makeIterator()) }

    public var description: String { allObjects.description }

    public var debugDescription: String { allObjects.debugDescription }

    public static func != (lhs: WeakSet<T>, rhs: WeakSet<T>) -> Bool { Set(lhs.allObjects.map(ObjectIdentifier.init)) != Set(rhs.allObjects.map(ObjectIdentifier.init)) }
}

#endif
