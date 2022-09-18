//
//  String+Acheron.swift
//  Acheron
//
//  Created by Joe Charlier on 4/23/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import Foundation

public extension String {
    subscript(i: Int) -> Character {										// [a]
        self[index(startIndex, offsetBy: i)]
    }
    subscript(r: CountableClosedRange<Int>) -> String {						// [a...b]
        let start = index(startIndex, offsetBy: r.lowerBound)
        let end = index(startIndex, offsetBy: r.upperBound)
        return String(self[start...end])
    }
    subscript(r: CountablePartialRangeFrom<Int>) -> String {				// [a...]
        let start = index(startIndex, offsetBy: r.lowerBound)
        let end = endIndex
        return String(self[start..<end])
    }
    subscript(r: PartialRangeThrough<Int>) -> String {						// [...b]
        let start = startIndex
        let end = index(startIndex, offsetBy: r.upperBound)
        return String(self[start...end])
    }
    subscript(r: PartialRangeUpTo<Int>) -> String {							// [..<b]
        guard r.upperBound > 0 else {return ""}
        let start = startIndex
        let end = index(startIndex, offsetBy: r.upperBound-1)
        return String(self[start...end])
    }
    func loc(of string: String, after: Int = 0) -> Int? {
        let sub = self[after...]
        guard let range = sub.range(of: string) else { return nil }
        return after + sub.distance(from: sub.startIndex, to: range.lowerBound)
    }
    func lastLoc(of string: String) -> Int? {
        guard let range = range(of: string, options: .backwards) else { return nil }
        return distance(from: string.startIndex, to: range.lowerBound)
    }
    var capitalize: String {
        guard let first = first else { return "" }
        return String(first).uppercased() + dropFirst()
    }

    var localized: String { NSLocalizedString(self, comment: "") }
    func toInt8() -> UnsafeMutablePointer<Int8> { UnsafeMutablePointer<Int8>(mutating: (self as NSString).utf8String!) }
    func toCString() -> [CChar]? { cString(using: .utf8) }
    
    func toAttributes() -> [String:Any] {
        guard self != "" else {return [:]}
        do {
            return try JSONSerialization.jsonObject(with: data(using: .utf8)!, options: [.allowFragments]) as? [String:Any] ?? [:]
        } catch {
            print("Error Attempting to Parse [\(self)]\n\(error)")
            return [:]
        }
    }
    func toArray() -> [[String:Any]] {
        guard self != "" else {return []}
        do {
            return try JSONSerialization.jsonObject(with: data(using: .utf8)!, options: [.allowFragments]) as! [[String:Any]]
        } catch {
            print("Error Attempting to Parse [\(self)]\n\(error)")
            return []
        }
    }
    
    static func uuid() -> String { UUID().uuidString }
    
#if !os(Linux)
    func xmlToAttributes() -> [String:Any] {
        let parser: XMLParser = XMLParser(data: data(using: .utf8)!)
        let delegate: XMLtoAttributes = XMLtoAttributes()
        parser.delegate = delegate
        parser.parse()
        return delegate.result
    }
#endif
}

#if canImport(UIKit)

import UIKit

public extension String {
    func size(pen: Pen) -> CGSize { (self as NSString).size(withAttributes: pen.attributes) }
    func size(pen: Pen, width: CGFloat) -> CGSize {
        (self as NSString).boundingRect(with: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude), options: [.usesLineFragmentOrigin , .usesFontLeading], attributes: pen.attributes, context: nil).size
    }
    func draw(at point: CGPoint, pen: Pen) { (self as NSString).draw(at: point, withAttributes: pen.attributes) }
    func draw(in rect: CGRect, pen: Pen) { (self as NSString).draw(in: rect, withAttributes: pen.attributes) }
    func draw(with rect: CGRect, options: NSStringDrawingOptions, pen: Pen, context: NSStringDrawingContext?) {
        (self as NSString).draw(with: rect, options: options, attributes: pen.attributes, context: context)
    }
    func attributed(pen: Pen) -> NSMutableAttributedString { NSMutableAttributedString(string: self, attributes: pen.attributes) }
}

#endif
