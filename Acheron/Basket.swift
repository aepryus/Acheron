//
//  Basket.swift
//  Acheron
//
//  Created by Joe Charlier on 4/23/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import Foundation

public class Basket: NSObject {
	let persist: Persist

	var blocks: [String:[(Domain)->()]] = [:]
	
	public var fork: Int

	var busy: Bool
	var cache: [String:Anchor] = [:]
	var onlyToIden: [String:String] = [:]
	var dirty = Set<Anchor>()
	var dehydrate = Set<Domain>()

	let queue: DispatchQueue
	
	let generateIden:(Domain.Type)->(String) = {(type: Domain.Type) -> (String) in
		return String.uuid()
	}
	
	public init(_ persist: Persist) {
		self.persist = persist
		queue = DispatchQueue(label: self.persist.name)
		busy = false
		fork = Int(persist.get(key: "fork") ?? "0")!
	}
	
	public func associate(type: String, only: String) {
		queue.sync {
			persist.associate(type: type, only: only)
		}
	}
		
	private func load(_ attributes: [String:Any], cls: Anchor.Type) -> Anchor {
		let anchor = cls.init(attributes: attributes)
		anchor.basket = self
		anchor.load(attributes: attributes)
		cache[anchor.iden] = anchor
		return anchor
	}
	private func load(_ attributes: [String:Any]) -> Anchor {
		let cls = Loom.classFromName(attributes["type"] as! String) as! Anchor.Type
		return load(attributes, cls: cls)
	}
	public func inject(_ attributes: [String:Any]) -> Anchor {
		let anchor = load(attributes)
		anchor.dirty()
		return anchor
	}
	
	public func createByClass(_ cls: Anchor.Type) -> Anchor {
		let anchor = cls.init(basket: self)
		anchor.iden = generateIden(cls)
		cache[anchor.iden] = anchor
		dirty.insert(anchor)
		return anchor
	}
	
	private func convert(array: [[String:Any]]) -> [Anchor] {
		var anchors = [Anchor]()
		for attributes in array {
			var anchor = cache[attributes["iden"] as! String]
			if anchor == nil {
				anchor = load(attributes)
			}
			anchors.append(anchor!)
		}
		return anchors;
	}
	private func convert(array: [[String:Any]], type:Anchor.Type) -> [Anchor] {
		var anchors = [Anchor]()
		for attributes in array {
			var anchor = cache[attributes["iden"] as! String]
			if anchor == nil {
				anchor = load(attributes, cls: type)
			}
			anchors.append(anchor!)
		}
		return anchors;
	}
	
	public func selectBy(iden: String) -> Anchor? {
		if let anchor = cache[iden] {
			return anchor
		}
		if let attributes = persist.attributes(iden: iden) {
			return load(attributes)
		}
		return nil
	}
	public func selectBy(type: String, only: String) -> Anchor? {
		if let iden = onlyToIden["\(type):\(only)"], let anchor = cache[iden] {
			return anchor
		}
		if let attributes = persist.attributes(type: type, only: only) {
			return load(attributes)
		}
		return nil
	}
	public func selectOne(where field: String, is value: String, type: Anchor.Type) -> Domain? {
		guard let attributes = persist.selectOne(where: field, is: value, type: Loom.nameFromType(type))
			else {return nil}
		var anchor = cache[attributes["iden"] as! String]
		if anchor == nil {
			anchor = load(attributes, cls: type)
		}
		return anchor
	}
	public func select(where field: String, is value: String, type: Anchor.Type) -> [Domain] {
		let array = persist.select(where: field, is: value, type: Loom.nameFromType(type))
		return convert(array: array, type:type)
	}
	public func selectAll(_ type: Anchor.Type) -> [Anchor] {
		let array = persist.selectAll(type: Loom.nameFromType(type))
		return convert(array: array, type: type)
	}
	public func selectForked() -> [Anchor] {
		let array = persist.selectForked()
		return convert(array: array)
	}
	public func selectForkedMemories() -> [[String:Any]] {
		return persist.selectForkedMemories()
	}
	
	public func syncPacket() -> [String:Any] {
		var attributes = [String:Any]()
		
		var documents =  [[String:Any]]()
		for anchor in selectForked() {
			if anchor.isUploaded {
				documents.append(anchor.unload())
			}
		}
		
		attributes["fork"] = persist.get(key: "fork")
		attributes["documents"] = documents
		attributes["deleted"] = []
		attributes["memories"] = selectForkedMemories()
		
		return attributes
	}
	
	func dirtyAnchor(_ anchor: Anchor) {
		dirty.insert(anchor)
	}
	func deleteAnchor(_ anchor: Anchor) {
		dirty.insert(anchor)
		cache.removeValue(forKey: anchor.iden)
	}
	
	func deleteByID(_ iden: String ) {}
	
	private func key(class cls: Domain.Type, action: DomainAction) -> String {
		return "\(String(describing: cls))_\(action)"
	}
	public func addBlock(_ block: @escaping (Domain)->(), class cls: Domain.Type, event: DomainAction) {
		addBlock(class: cls, action: event, block: block)
	}
	func addBlock(class cls: Domain.Type, action: DomainAction, block: @escaping (Domain)->()) {
		let key = self.key(class: cls, action: action)
		if blocks[key] == nil {
			blocks[key] = []
		}
		blocks[key]!.append(block)
	}
	func blocksFor(class cls: Domain.Type, action: DomainAction) -> [(Domain)->()] {
		let key = self.key(class: cls, action: action)
		return blocks[key] ?? []
	}
	
	static func loadDirty(into: inout Set<Domain>, domain: Domain) {
		into.insert(domain)
		for child in domain.allDomainChildren() {
			if child.status != .clean {
				loadDirty(into:&into, domain:child)
			}
		}
	}
	
	var semaphore = DispatchSemaphore(value: 1)
	public func lock() {
		semaphore.wait()
	}
	public func unlock() {
		semaphore.signal()
	}
	public func unlockedTransact(_ closure: ()->()) {
		if self.busy {fatalError("Do not nest transact blocks.")}
		
		busy = true
		
		var dirty = Set<Anchor>()
		
		var editedAnchors = Set<Anchor>()
		var deletedAnchors = Set<Anchor>()
		var editedDomains = Set<Domain>()
		var deletedDomains = Set<Domain>()
		
		queue.sync {
			autoreleasepool {
				closure()
				
				while self.dirty.count > 0 {
					dirty.formUnion(self.dirty)
					
					var dirtyDomains = Set<Domain>()
					for anchor in self.dirty {
						dirtyDomains.formUnion(anchor.deepSearchChildren({ (domain: Domain) -> (Bool) in
							return domain.status != .clean
						}))
					}
					self.dirty.removeAll()
					for domain in dirtyDomains {
						domain.dirtied()
					}
				}
				
				deletedDomains.formUnion(self.dehydrate)
				
				for anchor in dirty {
					if anchor.status == .deleted {
						deletedAnchors.insert(anchor)
						deletedDomains.insert(anchor)
					} else {
						editedAnchors.insert(anchor)
						Basket.loadDirty(into:&editedDomains, domain:anchor)
						anchor.save()
					}
				}
			}
		}
		
		if dirty.count > 0 {
			queue.sync {
				self.persist.transact({ () -> (Bool) in
					autoreleasepool {
						for anchor in deletedAnchors {
							persist.delete(iden: anchor.iden)
						}
						for anchor in editedAnchors {
							persist.store(iden: anchor.iden, attributes: anchor.unload())
						}
					}
					return true
				})
			}
		}
		
		busy = false
	}
	public func transact(_ closure: ()->()) {
		lock()
		defer {unlock()}
		unlockedTransact(closure)
	}
	
	public func clearCache() {
		cache.removeAll()
	}
	
	public func set(key: String, value: String) {
		persist.set(key: key, value: value)
	}
	public func setServer(key: String, value: String) {
		persist.setServer(key: key, value: value)
	}
	public func get(key: String) -> String? {
		return persist.get(key: key)
	}
	public func unset(key: String) {
		persist.unset(key: key)
	}
	
	public func show() {
		persist.show()
	}
	func showID(_ iden: String) {
		persist.show(iden)
	}
	
	public func wipe() {
		lock()
		defer {unlock()}
		persist.wipe()
		fork = 0
		cache.removeAll()
		dirty.removeAll()
		dehydrate.removeAll()
	}
	
	public func printStatus() {
		persist.show()
	}
}
