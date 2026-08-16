//
//  LoomTests.swift
//  Acheron
//
//  The same behaviors, in the macro dialect.
//

#if Weave

import XCTest
@testable import Acheron

class WeaveMemoryPersist: Persist {
    var rows: [String:[String:Any]] = [:]
    var kv: [String:String] = [:]

    override func selectAll(type: String) -> [[String:Any]] { rows.values.filter { $0["type"] as? String == type } }
    override func attributes(iden: String) -> [String:Any]? { rows[iden] }
    override func attributes(type: String, only: String) -> [String:Any]? {
        guard let key = typeToOnly[type] else { return nil }
        return rows.values.first { $0["type"] as? String == type && $0[key] as? String == only }
    }
    override func store(iden: String, attributes: [String:Any]) -> Bool { rows[iden] = attributes; return true }
    override func delete(iden: String) -> Bool { rows.removeValue(forKey: iden); return true }
    override func set(key: String, value: String) { kv[key] = value }
    override func get(key: String) -> String? { kv[key] }
}

enum Rating: String, Packable { case unknown, good, great }
struct Spec: Codable, Packable, Equatable {
    var thrust: Double = 0
    var name: String = ""
}

@Domain class Gadget: Domain {
    @Field var label: String = ""
}
@Domain class Widget: Anchor {
    @Field var name: String = ""
    @Field var flightNo: Int = 0
    @Field var when: Date = Date()
    @Field var rating: Rating = .unknown
    @Field var spec: Spec = Spec()
    @Child var gadgets: [Gadget] = []
}

final class WeaveTests: XCTestCase {
    var persist: WeaveMemoryPersist!
    var basket: Basket!

    override func setUp() {
        super.setUp()
        persist = WeaveMemoryPersist("test")
        basket = Basket(persist)
        Loom.basket = basket
        Loom.register([Widget.self, Gadget.self])
    }

    private func widgetWithGadget() -> (Widget, Gadget) {
        let widget: Widget = Loom.create()
        let gadget = Gadget()
        Loom.transact {
            widget.gadgets.append(gadget)
        }
        return (widget, gadget)
    }

// Documents =======================================================================================
    func testRoundTrip() {
        let widget: Widget = Loom.create()
        let iden: String = widget.iden
        Loom.transact {
            widget.name = "Falcon"
            widget.flightNo = 7
            let gadget = Gadget()
            gadget.label = "leg"
            widget.gadgets.append(gadget)
        }
        basket.clearCache()
        let reloaded: Widget = Loom.selectBy(iden: iden)!
        XCTAssertFalse(reloaded === widget)
        XCTAssertEqual(reloaded.name, "Falcon")
        XCTAssertEqual(reloaded.flightNo, 7)
        XCTAssertEqual(reloaded.gadgets.count, 1)
        XCTAssertEqual(reloaded.gadgets.first?.label, "leg")
    }
    func testTheAggregateIsOneDocument() {
        let (widget, gadget) = widgetWithGadget()
        Loom.transact { gadget.label = "arm" }
        XCTAssertEqual(persist.rows.count, 1)
        let kids = persist.rows[widget.iden]?["gadgets"] as? [[String:Any]]
        XCTAssertEqual(kids?.first?["label"] as? String, "arm")
    }

// Identity ========================================================================================
    func testIdentityMap() {
        let widget: Widget = Loom.create()
        Loom.transact { widget.name = "one" }
        let a: Widget = Loom.selectBy(iden: widget.iden)!
        let b: Widget = Loom.selectBy(iden: widget.iden)!
        XCTAssertTrue(a === b && a === widget)
    }
    func testHydrationMergesIntoLiveChildren() {
        let (widget, gadget) = widgetWithGadget()
        Loom.transact { gadget.label = "before" }
        var attributes = widget.unload()
        var kids = attributes["gadgets"] as! [[String:Any]]
        kids[0]["label"] = "after"
        attributes["gadgets"] = kids
        Loom.transact { widget.dirtyUsingAttributes(attributes) }
        XCTAssertTrue(widget.gadgets.first === gadget)
        XCTAssertEqual(gadget.label, "after")
    }
    func testOnlyKey() {
        basket.associate(type: "widget", only: "name")
        let widget: Widget = Loom.create(only: "solo")
        Loom.transact { widget.name = "solo" }
        basket.clearCache()
        let found: Widget? = Loom.selectBy(only: "solo")
        XCTAssertEqual(found?.name, "solo")
    }

// Capture =========================================================================================
    func testAssignmentIsTheAPI() {
        let widget: Widget = Loom.create()
        Loom.transact { widget.name = "v1" }
        XCTAssertEqual(widget.status, DomainStatus.clean)
        Loom.transact {
            widget.name = "v2"
            XCTAssertEqual(widget.status, DomainStatus.dirty)
        }
        XCTAssertEqual(persist.rows[widget.iden]?["name"] as? String, "v2")
    }
    func testChildEditDirtiesTheAnchor() {
        let (widget, gadget) = widgetWithGadget()
        Loom.transact { gadget.label = "wing" }
        let kids = persist.rows[widget.iden]?["gadgets"] as? [[String:Any]]
        XCTAssertEqual(kids?.first?["label"] as? String, "wing")
    }
    func testSelectInsideTransact() {
        let widget: Widget = Loom.create()
        Loom.transact { widget.name = "find" }
        var found: Widget? = nil
        Loom.transact { found = Loom.selectBy(iden: widget.iden) }
        XCTAssertTrue(found === widget)
    }

// Lifecycle =======================================================================================
    func testDeleteCascades() {
        let (widget, gadget) = widgetWithGadget()
        Loom.transact { widget.delete() }
        XCTAssertEqual(gadget.status, DomainStatus.deleted)
        XCTAssertNil(persist.rows[widget.iden])
        XCTAssertNil(basket.selectBy(iden: widget.iden))
    }
    /// Removal is two steps: drop it from the parent's array AND remove(_:).  Calling
    /// remove(_:) alone leaves save() reaching a deleted child, which trips Domain's
    /// stale-object guard.
    func testRemoveRetiresTheChild() {
        let (widget, gadget) = widgetWithGadget()
        Loom.transact { widget.gadgets.removeAll { $0 === gadget } }
        XCTAssertEqual(gadget.status, DomainStatus.deleted)
        XCTAssertEqual((persist.rows[widget.iden]?["gadgets"] as? [[String:Any]])?.count ?? 0, 0)
    }

// Values ==========================================================================================
    func testDateRoundTrip() {
        let widget: Widget = Loom.create()
        let date = Date(timeIntervalSinceReferenceDate: 700000000)
        Loom.transact { widget.when = date }
        basket.clearCache()
        let reloaded: Widget = Loom.selectBy(iden: widget.iden)!
        XCTAssertEqual(Int(reloaded.when.timeIntervalSinceReferenceDate), 700000000)
    }
    func testAdditiveEvolutionIsFree() {
        let widget: Widget = Loom.create()
        Loom.transact { widget.name = "additive" }
        var attributes = persist.rows[widget.iden]!
        attributes["fieldFromAFutureVersion"] = "ignored"
        attributes.removeValue(forKey: "flightNo")
        basket.clearCache()
        persist.rows[widget.iden] = attributes
        let reloaded: Widget = Loom.selectBy(iden: widget.iden)!
        XCTAssertEqual(reloaded.name, "additive")
        XCTAssertEqual(reloaded.flightNo, 0)
    }

// Free mode =======================================================================================
    func testFreeModeRoundTrip() {
        let gadget = Gadget()
        gadget.label = "free"
        let attributes = gadget.unload()
        let clone = Gadget(attributes: attributes)
        clone.load(attributes: attributes)
        XCTAssertFalse(clone === gadget)
        XCTAssertEqual(clone.label, "free")
    }
    func testReplicateGivesFreshIdens() {
        let (widget, gadget) = widgetWithGadget()
        let copy = Loom.domain(attributes: widget.unload(), replicate: true) as! Widget
        XCTAssertNotEqual(copy.iden, widget.iden)
        XCTAssertEqual(copy.gadgets.count, 1)
        XCTAssertNotEqual(copy.gadgets.first?.iden, gadget.iden)
    }

// Dialect =========================================================================================
    func testEnumsAndCodableAreFields() {
        let widget: Widget = Loom.create()
        Loom.transact {
            widget.rating = .great
            widget.spec = Spec(thrust: 9.81, name: "raptor")
        }
        XCTAssertEqual(persist.rows[widget.iden]?["rating"] as? String, "great")
        basket.clearCache()
        let reloaded: Widget = Loom.selectBy(iden: widget.iden)!
        XCTAssertEqual(reloaded.rating, Rating.great)
        XCTAssertEqual(reloaded.spec, Spec(thrust: 9.81, name: "raptor"))
    }
    func testAppendWiresTheChild() {
        let widget: Widget = Loom.create()
        let gadget = Gadget()
        Loom.transact { widget.gadgets.append(gadget) }
        XCTAssertTrue(gadget.parent === widget)
    }
    func testAwaitTransact() async {
        let widget: Widget = Loom.create()
        await Loom.transact { widget.name = "awaited" }
        XCTAssertEqual(persist.rows[widget.iden]?["name"] as? String, "awaited")
    }

// Sync ============================================================================================
    func testInjectRunsInsideATransact() {
        let attributes: [String:Any] = ["iden":"inj-1", "type":"widget", "name":"beamed", "flightNo":3]
        var injected: Widget! = nil
        Loom.transact { injected = basket.inject(attributes) as? Widget }
        XCTAssertEqual(injected.name, "beamed")
        XCTAssertEqual(persist.rows["inj-1"]?["name"] as? String, "beamed")
    }

// Sync columns ====================================================================================
    func testForkAndVersPersist() {
        let widget: Widget = Loom.create()
        Loom.transact { widget.name = "sync" }
        XCTAssertEqual(persist.rows[widget.iden]?["fork"] as? Int, 1)
        XCTAssertEqual(persist.rows[widget.iden]?["vers"] as? Int, 0)
        persist.rows[widget.iden]?["fork"] = 4
        persist.rows[widget.iden]?["vers"] = 7
        basket.clearCache()
        let reloaded: Widget = Loom.selectBy(iden: widget.iden)!
        XCTAssertEqual(reloaded.fork, 4)
        XCTAssertEqual(reloaded.vers, 7)
    }
}

#endif
