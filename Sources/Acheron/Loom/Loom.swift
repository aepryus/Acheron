//
//  Loom.swift
//  Acheron
//
//  Created by Joe Charlier on 4/23/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

#if !os(Linux)

import Foundation

public class Loom {
    public static var basket: Basket!

    public static var namespaces: [String] = []
    static var domains = [String:[String:AnyClass]]()

    static func nameFromType(_ type: Domain.Type) -> String {
        let fullname: String = NSStringFromClass(type)
        let name = String(fullname[fullname.range(of: ".")!.upperBound...])
        return name[0...0].lowercased()+name[1...]
    }
    static func classFromName(_ name: String) -> AnyClass? {
        var cls: AnyClass? = nil
        for namespace in Loom.namespaces {
            let fullname = namespace + "." + name[0...0].uppercased()+name[1...]
            cls =  NSClassFromString(fullname)
            if cls != nil { break }
        }
        return cls
    }
    
    public static func classForKeyPath(keyPath: String, parent: Domain.Type) -> AnyClass? {
        var n: UInt32 = 0
        guard let properties: UnsafeMutablePointer<objc_property_t> = class_copyPropertyList(parent, &n) else { return nil }
        var cls: AnyClass?
        
        for i in 0..<Int(n) {
            let name = String(validatingUTF8: property_getName(properties[i]))
            if keyPath != name { continue }
            
            let attributes: UnsafePointer<Int8> = property_getAttributes(properties[i])!
            if attributes[1] == Int8(UInt8(ascii:"@")) {
                var className: String = String()
                var j = 3
                while attributes[j] != 0 && attributes[j] != Int8(UInt8(ascii:"\"")) {
                    className.append(Character(UnicodeScalar(UInt8(attributes[j]))))
                    j += 1
                }
                cls = NSClassFromString(className)
            }
            break;
        }
        free(properties)
        
        if cls == nil {
            let superclass: NSObject.Type = class_getSuperclass(parent) as! NSObject.Type
            if superclass != NSObject.self {
                cls = classForKeyPath(keyPath: keyPath, parent: superclass as! Domain.Type)
            }
        }
        
        return cls
    }
    public static func arrayClassForKeyPath(keyPath: String, parent: AnyObject) -> AnyClass? {
        let mirror: Mirror = Mirror(reflecting: parent)
        for property in mirror.children {
            guard property.label! == keyPath else {continue}
            var className = "\(Swift.type(of: property.value))"
            if className.starts(with: "Array<") {
                className.removeLast(1)
                className.removeFirst(6)
                for namespace in Loom.namespaces {
                    if let cls = NSClassFromString("\(namespace).\(className)") {
                        return cls
                    }
                }
            }
            return nil
        }
        return nil
    }
    
    public static func set(key: String, value: String) {
        Loom.basket.set(key: key, value: value)
    }
    public static func get(key: String) -> String? {
        return Loom.basket.get(key: key)
    }
    public static func unset(key: String) {
        Loom.basket.unset(key: key)
    }
    public static func create<T: Anchor>(only: String? = nil) -> T {
        return Loom.basket.createBy(cls: T.self, only: only) as! T
    }
    
    public static func selectBy<T: Anchor>(iden: String) -> T? {
        return Loom.basket.selectBy(iden: iden) as? T
    }
    public static func selectBy<T: Anchor>(only: String) -> T? {
        return Loom.basket.selectBy(cls: T.self, only: only) as? T
    }
    public static func selectOne<T: Anchor>(where field: String, is value: String) -> T? {
        return Loom.basket.selectOne(where: field, is: value, type: T.self) as? T
    }
    public static func select<T: Anchor>(where field: String, is value: String) -> [T] {
        return Loom.basket.select(where: field, is: value, type: T.self) as! [T]
    }
    public static func selectAll<T: Anchor>() -> [T] {
        return Loom.basket.selectAll(T.self) as! [T]
    }
    
    public static func transact(_ closure: ()->()) {
        Loom.basket.transact(closure)
    }
    
    public static func start(basket: Basket, namespaces: [String]) {
        Loom.basket = basket
        Loom.namespaces = namespaces
    }
}

#endif
