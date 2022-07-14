//
//  XMLtoAttributes.swift
//  Acheron
//
//  Created by Joe Charlier on 5/7/20.
//  Copyright © 2020 Aepryus Software. All rights reserved.
//

import Foundation
#if canImport(FoundationXML)
import FoundationXML
#endif

fileprivate class AnyStack {
	var stack: [[String:Any]] = []
	
	func push(_ attributes: [String:Any]) {
		stack.append(attributes)
	}
	func pop() -> [String:Any] {
		return stack.removeLast()
	}
	var top: [String:Any]? {
		set {
			stack.removeLast()
			if let newValue = newValue {
				stack.append(newValue)
			}
		}
		get { stack.last }
	}
}

class XMLtoAttributes: NSObject, XMLParserDelegate {
	var result: [String:Any] = [:]
	fileprivate var stack: AnyStack = AnyStack()

// XMLParserDelegate ===============================================================================
	func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
		var attributes: [String:Any] = [:]
		attributes["type"] = elementName
		for key in attributeDict.keys {
			attributes[key] = attributeDict[key]
		}
		stack.push(attributes)
	}
	func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
		let node: [String:Any] = stack.pop()
		
		if stack.top != nil {
			var children: [[String:Any]] = stack.top!["children"] as? [[String:Any]] ?? []
			children.append(node)
			stack.top!["children"] = children
		} else {
			result = node
		}
	}
}
