//
//  Persist.swift
//  Acheron
//
//  Created by Joe Charlier on 4/23/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

#if !os(Linux)

import Foundation

open class Persist: NSObject {
    open var name: String
    var typeToOnly: [String:String] = [:]

    public init(_ name: String) {
        self.name = name
    }
    
    public func associate(type: String, only: String) { typeToOnly[type] = only }
    public func only(type: String) -> String? { typeToOnly[type] }

    open func selectAll() -> [[String:Any]] { [] }
    open func selectAll(type: String) -> [[String:Any]] { [] }
    open func select(where: String, is value: String?, type: String) -> [[String:Any]] { [] }
    open func selectOne(where: String, is value: String, type: String) -> [String:Any]? { nil }
    
    open func selectForked() -> [[String:Any]] { [] }
    open func selectForkedMemories() -> [[String:Any]] { [] }
    
    open func attributes(iden: String) -> [String:Any]? { nil }
    open func attributes(type: String, only: String) -> [String:Any]? { nil }
    
    open func delete(iden: String) {}
    open func store(iden: String, attributes: [String:Any]) {}
    
    open func transact(_ closure: ()->(Bool)) { _ = closure() }
    
    open func wipe() {}
    open func wipeDocuments() {}
    
    open func show() {}
    open func show(_ iden: String) {}
    open func census() {}

    open func set(key: String, value: String) {}
    open func setServer(key: String, value: String) {}
    open func get(key: String) -> String? { nil }
    open func unset(key: String) {}
    
    open func logError(_ error: Error) {}
    open func logError(message: String) {}
}

#endif
