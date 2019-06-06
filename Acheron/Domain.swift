//
//  Domain.swift
//  Acheron
//
//  Created by Joe Charlier on 4/23/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import Foundation

public enum DomainStatus {
	case loading, clean, dirty, deleted
}
public enum DomainAction: String {
	case create, edit, delete, added, removed, load, save, dirty
}

class NotFound {}

public protocol Packable where Self:NSObject {
	init(_: String)
	func pack() -> String
}

open class Domain: NSObject {
	
	// Properties
	@objc public dynamic var iden: String!
	@objc public dynamic var type: String!
	@objc public dynamic var modified: Date!
	
	// Transient
	weak public var parent: Domain?
	private var _status: DomainStatus = .loading
	public var status: DomainStatus {
		set {
			guard _status != newValue else {return}
			
			objc_sync_enter(self)
			defer {objc_sync_exit(self)}
			
			if _status == .loading && newValue == .dirty {
				
			} else if (_status == .loading || status == .dirty) && newValue == .clean {
				subscribe()
				
			} else if _status == .clean && (newValue == .dirty || newValue == .deleted) {
				unsubscribe()
				
			} else if (_status == .clean || _status == .dirty) && newValue == .deleted {
				
			} else {
				print("transition error: [\((String(describing: Swift.type(of: self))))] moving from \(_status) to \(newValue)")
			}
			
			_status = newValue
			
			if _status == .clean && isStatic == false && subscribed == false {fatalError()}
		}
		get {return _status}
	}
	
	var subscribed: Bool = false
	
	// Inits
	public override init() {
		self.iden = UUID().uuidString
		self.type = Loom.nameFromType(Swift.type(of: self))
		super.init()
		create()
	}
	public init(parent: Domain) {
		self.iden = UUID().uuidString
		self.type = Loom.nameFromType(Swift.type(of: self))
		self.parent = parent
		super.init()
		load()
	}
	public required init(attributes: [String:Any], parent: Domain? = nil) {
		self.iden = attributes["iden"] as? String
		self.type = attributes["type"] as? String
		self.parent = parent
		super.init()
//		load(attributes: attributes)
	}
	
	deinit {
		if status == .clean {
			unsubscribe()
		}
	}
	
	// Methods
	func load(_ domain: Domain) {
		domain.parent = self
		domain.onLoaded()
	}
	public func add(_ domain: Domain) {
		load(domain)
		domain.onAdded()
		edit()
		domain.handleTriggers(self, action: .added)
	}
	public func remove(_ domain: Domain) {
		domain.onRemoved()
		domain.parent = nil
		domain.delete()
		edit()
		domain.handleTriggers(domain, action: .removed)
	}
	
	func allDomainChildren() -> [Domain] {
		var result: [Domain] = []
		
		for keyPath in children {
			if let domains = self.value(forKeyPath: keyPath) as? [Domain] {
				result += domains
			}
		}
		
		return result
	}
	func deepSearchChildren(_ search: (Domain)->(Bool)) -> Set<Domain> {
		var result: Set<Domain> = []
		
		if search(self) {
			result.insert(self)
		}
		
		for domain in allDomainChildren() {
			result.formUnion(domain.deepSearchChildren(search))
		}
		
		return result
	}
	private func classForKeyPath(_ keyPath: String) -> AnyClass? {
		var propertyToClass = Loom.domains[type]
		if propertyToClass == nil {
			propertyToClass = [String:AnyClass]()
			Loom.domains[type] = propertyToClass;
		}
		var cls: AnyClass? = propertyToClass![keyPath];
		if cls == nil {
			cls = Loom.classForKeyPath(keyPath: keyPath, parent: Swift.type(of:self))
			if cls != nil {
				propertyToClass![keyPath] = cls
			} else {
				propertyToClass![keyPath] = NotFound.self
			}
		} else if cls === NotFound.self {
			cls = nil
		}
		return cls
	}
	private func arrayClassForKeyPath(_ keyPath: String) -> AnyClass? {
		var propertyToClass = Loom.domains[type]
		if propertyToClass == nil {
			propertyToClass = [String:AnyClass]()
			Loom.domains[type] = propertyToClass;
		}
		var cls: AnyClass? = propertyToClass![keyPath];
		if cls == nil {
			cls = Loom.arrayClassForKeyPath(keyPath: keyPath, parent: self)
			if cls != nil {
				propertyToClass![keyPath] = cls
			} else {
				propertyToClass![keyPath] = NotFound.self
			}
		} else if cls === NotFound.self {
			cls = nil
		}
		return cls
	}

	private func subscribe() {
		if isStatic {return}
		for keyPath in properties {
			addObserver(self, forKeyPath: keyPath, options: [.new,.old], context: nil)
		}
		subscribed = true
	}
	private func unsubscribe() {
		if isStatic {return}
		for keyPath in properties {
			removeObserver(self, forKeyPath: keyPath)
		}
		subscribed = false
	}
	
	private func handleTriggers(_ domain: Domain, action: DomainAction) {
		guard let basket = domain.anchor?.basket else {return}
		for block in basket.blocksFor(class: Swift.type(of: domain), action: action) {
			block(domain)
		}
	}
	
// Actions =========================================================================================
	func create() {
		modified = Date.now
		onCreate()
		handleTriggers(self, action: .create)
	}
	func edit() {
		dirty()
		modified = Date.now
		onEdit()
		handleTriggers(self, action: .edit)
		parent?.edit()
	}
	public func delete() {
		status = .deleted
		modified = Date.now
		onDelete()
		handleTriggers(self, action: .delete)
		for domain in allDomainChildren() {
			domain.delete()
		}
	}
	
	func dirty() {
		guard status != .deleted else {return}
		status = .dirty
	}
	func dirtied() {
		onDirty()
		handleTriggers(self, action: .dirty)
	}
	
	func load() {
		status = .clean
		onLoad()
		handleTriggers(self, action: .load)
	}
	func save() {
		status = .clean
		onSave()
		handleTriggers(self, action: .save)
		for domain in allDomainChildren() {
			domain.save()
		}
	}
	
// Events ==========================================================================================
	open func onCreate() {}
	open func onEdit() {}
	open func onDelete() {}
	
	open func onLoaded() {}
	open func onAdded() {}
	open func onRemoved() {}
	
	open func onInit() {}
	open func onDirty() {}
	
	open func onSave() {}
	open func onLoad() {}
	
// Load and Unload =================================================================================
	open func loader(keyPath: String) -> ((Any)->(Any?))? {
		return nil
	}
	open func unloader(keyPath: String) -> ((Any)->(Any?))? {
		return nil
	}
	
	public func unload() -> [String:Any] {
		var attributes = [String:Any]()
		
		for keyPath in properties {
			let value = self.value(forKeyPath: keyPath) as Any?
			let unloader = self.unloader(keyPath:keyPath)
			if let unloader = unloader {
				attributes[keyPath] = unloader(value!)
			} else if let value = value as? Date {
				attributes[keyPath] = value.toISOFormattedString() as NSString
			} else if let value = value as? Packable {
				attributes[keyPath] = value.pack()
			} else if let value = value as? Domain {
				attributes[keyPath] = value.unload() as NSDictionary
			} else {
				attributes[keyPath] = value
			}
		}
		for keyPath in children {
			let domains = value(forKeyPath: keyPath) as! [Any]
			if domains.count == 0 {
				attributes.removeValue(forKey: keyPath)
				continue
			}
			var array: [Any] = []
			if let domains = domains as? [Domain] {
				domains.forEach {array.append($0.unload())}
			} else if let packables = domains as? [Packable] {
				packables.forEach {array.append($0.pack())}
			} else if let strings = domains as? [String] {
				strings.forEach {array.append($0)}
			}
			attributes[keyPath] = array as NSArray;
		}
		
		return attributes
	}
	
	private func indexOfChildren(_ keyPath: String) -> [String:Domain] {
		var index: [String:Domain] = [:]
		
		let domains = value(forKeyPath: keyPath) as! [Domain]
		for domain in domains {
			index[domain.iden] = domain
		}
		
		return index
	}
	private func isOptional(_ instance: Any) -> Bool {
		let mirror = Mirror(reflecting: instance)
		let style = mirror.displayStyle
		return style == .optional
	}
	public func load(attributes: [String:Any]) {
		// Properties
		for keyPath in properties {
			var value = attributes[keyPath];
			if value != nil {
				let loader = self.loader(keyPath:keyPath)
				if let loader = loader {
					let newValue = loader(value!)
					if let newValue = newValue {
						value = newValue
					} else {
						value = NSNumber(value: 0)
					}
				} else {
					let cls: AnyClass? = classForKeyPath(keyPath)
					if cls == NSDate.self {
						if let string = value as? String {
							var time = Date.fromISOFormatted(string: string)
							if time == nil {
								time = nil
							}
							value = time
						} else {
							value = NSDate(timeIntervalSinceReferenceDate: Double(value as! String)!)
						}
					} else if let cls = cls as? Packable.Type {
						value = cls.init(value as! String)
					} else if cls?.superclass() == Domain.self {
						let valueAtts = value as! [String:Any]
						let cls = Loom.classFromName(valueAtts["type"] as! String) as! Domain.Type
						let domain = cls.init(attributes: valueAtts, parent: nil)
						domain.load(attributes:valueAtts)
						load(domain)
						value = domain;
					}
				}
			}
			
			if value != nil {setValue(value, forKey: keyPath)}
			else {
				if let currentValue = self.value(forKeyPath: keyPath) as Any? {
					if isOptional(currentValue) {
						setValue(nil, forKey: keyPath)
					}
				}
			}
		}
		// Children
		for keyPath in children {
			
			let children = attributes[keyPath] as! [Any]?
			if let children = children  {
				if children.count == 0 {continue}
				
				var array: [Any] = []
				
				if children.first is [String:Any] {
					let existing = indexOfChildren(keyPath)
					for child in children as! [[String:Any]] {
						var domain: Domain? = existing[child["iden"] as! String]
						if domain == nil {
							let cls = Loom.classFromName(child["type"] as! String) as! Domain.Type
							domain = cls.init(attributes: child, parent: self)
						}
						domain!.load(attributes:child)
						load(domain!)
						array.append(domain!)
					}
				} else if let cls = arrayClassForKeyPath(keyPath) as? Packable.Type {
					for package in children as! [String] {
						array.append(cls.init(package))
					}
				} else {
					for string in children as! [String] {
						array.append(string)
					}
				}
				setValue(array, forKey: keyPath)
			}
		}
		load()
	}
	public func dirtyUsingAttributes(_ attributes: [String:Any]) {
		dirty()
		for child in deepSearchChildren({ (domain) -> (Bool) in return true }) {
			child.dirty()
		}
		load(attributes: attributes)
	}
	public func dirtyUsingDomain(_ domain: Domain) {
		dirtyUsingAttributes(domain.unload())
	}
	public func editUsingAttributes(_ attributes: [String:Any]) {
		edit()
		load(attributes: attributes)
	}
	public func editUsingDomain(_ domain: Domain) {
		editUsingAttributes(domain.unload())
	}
	
// Domain ==========================================================================================
	open var properties: [String] {
		return ["iden", "type", "modified"]
	}
	open var children: [String] {
		return []
	}
	var isStatic: Bool {
		return false
	}
	public var anchor: Anchor? {
		get {return parent?.anchor}
	}
	
// NSObject ========================================================================================
	override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		let oldValue = change?[.oldKey] as? NSObject
		let newValue = change?[.newKey] as? NSObject
		if newValue != oldValue {edit()}
	}
}
