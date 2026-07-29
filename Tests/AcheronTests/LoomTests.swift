import XCTest
@testable import Acheron

class MemoryPersist: Persist {
    var rows: [String:[String:Any]] = [:]
    var kv: [String:String] = [:]
    var failNextCommit: Bool = false
    private let lock = NSRecursiveLock()

    private func locked<T>(_ block: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return block()
    }

    override func selectAll(type: String) -> [[String:Any]] { locked { rows.values.filter { $0["type"] as? String == type } } }
    override func attributes(iden: String) -> [String:Any]? { locked { rows[iden] } }
    override func attributes(type: String, only: String) -> [String:Any]? {
        locked {
            guard let key = typeToOnly[type] else { return nil }
            return rows.values.first { $0["type"] as? String == type && $0[key] as? String == only }
        }
    }
    override func store(iden: String, attributes: [String:Any]) -> Bool { locked { rows[iden] = attributes }; return true }
    override func delete(iden: String) -> Bool { locked { rows.removeValue(forKey: iden) }; return true }
    override func transact(_ closure: ()->(Bool)) -> Bool {
        locked {
            let snapshot = rows
            let ok = closure() && !failNextCommit
            if !ok { rows = snapshot }
            failNextCommit = false
            return ok
        }
    }
    override func set(key: String, value: String) { locked { kv[key] = value } }
    override func get(key: String) -> String? { locked { kv[key] } }
}

struct Vector: Packable, Equatable {
    let x: Double, y: Double
    init(_ x: Double, _ y: Double) { self.x = x; self.y = y }
    init?(_ string: String) {
        let parts = string.split(separator: ",").compactMap { Double($0) }
        guard parts.count == 2 else { return nil }
        x = parts[0]; y = parts[1]
    }
    func pack() -> String { "\(x),\(y)" }
}

struct Spec: Codable, Packable, Equatable {
    var thrust: Double = 0
    var name: String = ""
}

@Domain class Gizmo: Domain {
    @Field var tag: String = ""
    var addedCount: Int = 0
    override func onAdded() { addedCount += 1 }
}
@Domain class Gadget: Domain {
    @Field var label: String = ""
    @Child var gizmos: [Gizmo] = []
    var addedCount: Int = 0
    var removedCount: Int = 0
    override func onAdded() { addedCount += 1 }
    override func onRemoved() { removedCount += 1 }
}
@Domain class Widget: Anchor {
    @Field var name: String = ""
    @Field var flightNo: Int = 0
    @Field var active: Bool = false
    @Field var when: Date = Date()
    @Field var note: String? = nil
    @Field var thrust: Vector = Vector(0, 0)
    @Field var path: [Vector] = []
    @Field var tags: [String] = []
    @Field var spec: Spec = Spec()
    @Field var spare: Gizmo? = nil
    @Child var pilot: Gizmo? = nil
    @Child var gadgets: [Gadget] = []
}

final class LoomTests: XCTestCase {
    var persist: MemoryPersist!
    var basket: Basket!

    override func setUp() {
        super.setUp()
        persist = MemoryPersist("test")
        basket = Basket(persist)
        Loom.basket = basket
        Loom.register([Widget.self, Gadget.self, Gizmo.self])
    }

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

    func testIdentityMap() {
        let widget: Widget = Loom.create()
        Loom.transact { widget.name = "one" }
        let a: Widget = Loom.selectBy(iden: widget.iden)!
        let b: Widget = Loom.selectBy(iden: widget.iden)!
        XCTAssertTrue(a === b && a === widget)
    }

    func testOnlyKey() {
        basket.associate(type: "widget", only: "name")
        let widget: Widget = Loom.create(only: "solo")
        Loom.transact { widget.name = "solo" }
        basket.clearCache()
        let found: Widget? = Loom.selectBy(only: "solo")
        XCTAssertEqual(found?.name, "solo")
    }

    func testSweep() {
        basket.discipline = .tolerant
        let widget: Widget = Loom.create()
        Loom.transact { widget.name = "v1" }
        widget.name = "v2"
        Loom.transact {}
        XCTAssertEqual(persist.rows[widget.iden]?["name"] as? String, "v2")
    }

    func testFailedCommitRetries() {
        let widget: Widget = Loom.create()
        Loom.transact { widget.name = "v1" }
        persist.failNextCommit = true
        Loom.transact { widget.name = "v2" }
        XCTAssertEqual(persist.rows[widget.iden]?["name"] as? String, "v1")
        XCTAssertEqual(widget.status, DomainStatus.clean)
        Loom.transact {}
        XCTAssertEqual(persist.rows[widget.iden]?["name"] as? String, "v2")
    }

    func testPendingSuperseded() {
        let widget: Widget = Loom.create()
        Loom.transact { widget.name = "v1" }
        persist.failNextCommit = true
        Loom.transact { widget.name = "v2" }
        Loom.transact { widget.name = "v3" }
        XCTAssertEqual(persist.rows[widget.iden]?["name"] as? String, "v3")
    }

    func testNestedTransact() {
        let widget: Widget = Loom.create()
        Loom.transact {
            widget.name = "outer"
            Loom.transact { widget.flightNo = 9 }
            Loom.transact {}
        }
        XCTAssertEqual(persist.rows[widget.iden]?["name"] as? String, "outer")
        XCTAssertEqual(persist.rows[widget.iden]?["flightNo"] as? Int, 9)
    }

    func testSelectInsideTransact() {
        let widget: Widget = Loom.create()
        Loom.transact { widget.name = "find" }
        var found: Widget? = nil
        Loom.transact { found = Loom.selectBy(iden: widget.iden) }
        XCTAssertTrue(found === widget)
    }

    func testChildAppendWiresParent() {
        let widget: Widget = Loom.create()
        let gadget = Gadget()
        Loom.transact { widget.gadgets.append(gadget) }
        XCTAssertTrue(gadget.parent === widget)
        Loom.transact { gadget.label = "arm" }
        XCTAssertEqual((persist.rows[widget.iden]?["gadgets"] as? [[String:Any]])?.first?["label"] as? String, "arm")
    }

    func testChildRemovalDeletes() {
        let widget: Widget = Loom.create()
        let gadget = Gadget()
        Loom.transact { widget.gadgets.append(gadget) }
        Loom.transact { widget.gadgets.removeAll() }
        XCTAssertEqual(gadget.status, DomainStatus.deleted)
        XCTAssertEqual((persist.rows[widget.iden]?["gadgets"] as? [[String:Any]])?.count ?? 0, 0)
    }

    func testChildMove() {
        let w1: Widget = Loom.create()
        let w2: Widget = Loom.create()
        let gadget = Gadget()
        Loom.transact { w1.gadgets.append(gadget) }
        Loom.transact {
            w2.gadgets.append(gadget)
            w1.gadgets.removeAll()
        }
        XCTAssertNotEqual(gadget.status, DomainStatus.deleted)
        XCTAssertTrue(gadget.parent === w2)
        XCTAssertEqual((persist.rows[w1.iden]?["gadgets"] as? [[String:Any]])?.count ?? 0, 0)
        XCTAssertEqual((persist.rows[w2.iden]?["gadgets"] as? [[String:Any]])?.count, 1)
    }

    func testDelete() {
        let widget: Widget = Loom.create()
        Loom.transact { widget.name = "gone" }
        Loom.transact { widget.delete() }
        XCTAssertNil(persist.rows[widget.iden])
        XCTAssertNil(basket.selectBy(iden: widget.iden))
    }

    func testFieldMenagerieRoundTrip() {
        let widget: Widget = Loom.create()
        Loom.transact {
            widget.active = true
            widget.note = "check"
            widget.thrust = Vector(3, 4)
            widget.path = [Vector(0, 0), Vector(1, 1)]
            widget.tags = ["fast", "red"]
        }
        Loom.transact { widget.tags.append("blue") }
        basket.clearCache()
        let reloaded: Widget = Loom.selectBy(iden: widget.iden)!
        XCTAssertEqual(reloaded.active, true)
        XCTAssertEqual(reloaded.note, "check")
        XCTAssertEqual(reloaded.thrust, Vector(3, 4))
        XCTAssertEqual(reloaded.path, [Vector(0, 0), Vector(1, 1)])
        XCTAssertEqual(reloaded.tags, ["fast", "red", "blue"])
    }

    func testOptionalNilRoundTrip() {
        let widget: Widget = Loom.create()
        Loom.transact { widget.note = "temp" }
        Loom.transact { widget.note = nil }
        basket.clearCache()
        let reloaded: Widget = Loom.selectBy(iden: widget.iden)!
        XCTAssertNil(reloaded.note)
        XCTAssertNil(reloaded.spare)
        XCTAssertNil(reloaded.pilot)
    }

    func testLegacyNSNumberLoad() {
        let widget: Widget = Loom.create()
        Loom.transact { widget.name = "raw" }
        persist.rows[widget.iden]?["active"] = NSNumber(value: true)
        persist.rows[widget.iden]?["flightNo"] = NSNumber(value: 42)
        basket.clearCache()
        let reloaded: Widget = Loom.selectBy(iden: widget.iden)!
        XCTAssertEqual(reloaded.active, true)
        XCTAssertEqual(reloaded.flightNo, 42)
    }

    func testDomainValueFieldDoesNotWire() {
        let widget: Widget = Loom.create()
        let gizmo = Gizmo()
        gizmo.tag = "data"
        Loom.transact { widget.spare = gizmo }
        XCTAssertNil(gizmo.parent)
        basket.clearCache()
        let reloaded: Widget = Loom.selectBy(iden: widget.iden)!
        XCTAssertEqual(reloaded.spare?.tag, "data")
    }

    func testChildScalarWires() {
        let widget: Widget = Loom.create()
        let gizmo = Gizmo()
        Loom.transact { widget.pilot = gizmo }
        XCTAssertTrue(gizmo.parent === widget)
        Loom.transact { gizmo.tag = "ace" }
        XCTAssertEqual((persist.rows[widget.iden]?["pilot"] as? [String:Any])?["tag"] as? String, "ace")
    }

    func testEqualValueSetStaysClean() {
        basket.discipline = .tolerant
        let widget: Widget = Loom.create()
        Loom.transact { widget.name = "same" }
        widget.name = "same"
        XCTAssertEqual(widget.status, DomainStatus.clean)
        widget.name = "different"
        XCTAssertEqual(widget.status, DomainStatus.dirty)
    }

    func testChildEventsFireOnce() {
        var addedBlocks = 0, removedBlocks = 0
        basket.addBlock({ _ in addedBlocks += 1 }, class: Widget.self, event: .added)
        basket.addBlock({ _ in removedBlocks += 1 }, class: Gadget.self, event: .removed)
        let widget: Widget = Loom.create()
        let gadget = Gadget()
        Loom.transact {
            widget.gadgets.append(gadget)
            widget.add(gadget)
        }
        XCTAssertEqual(gadget.addedCount, 1)
        XCTAssertEqual(addedBlocks, 1)
        Loom.transact {
            widget.gadgets.removeAll()
            widget.remove(gadget)
        }
        XCTAssertEqual(gadget.removedCount, 1)
        XCTAssertEqual(removedBlocks, 1)
        XCTAssertEqual(gadget.status, DomainStatus.deleted)
    }

    func testHydrationFiresNoEvents() {
        let widget: Widget = Loom.create()
        Loom.transact { widget.gadgets.append(Gadget()) }
        basket.clearCache()
        let reloaded: Widget = Loom.selectBy(iden: widget.iden)!
        XCTAssertEqual(reloaded.gadgets.first?.addedCount, 0)
        XCTAssertTrue(reloaded.gadgets.first?.parent === reloaded)
    }

    func testReorderCapturesAndPersists() {
        let widget: Widget = Loom.create()
        let a = Gadget(), b = Gadget()
        a.label = "a"; b.label = "b"
        Loom.transact { widget.gadgets = [a, b] }
        Loom.transact { widget.gadgets = [b, a] }
        XCTAssertEqual(a.addedCount, 1)
        XCTAssertEqual(a.removedCount, 0)
        let labels = (persist.rows[widget.iden]?["gadgets"] as? [[String:Any]])?.map { $0["label"] as? String }
        XCTAssertEqual(labels, ["b", "a"])
    }

    func testGrandchildDirtiesAnchor() {
        let widget: Widget = Loom.create()
        let gadget = Gadget(), gizmo = Gizmo()
        Loom.transact {
            widget.gadgets.append(gadget)
            gadget.gizmos.append(gizmo)
        }
        XCTAssertTrue(gizmo.parent === gadget)
        Loom.transact { gizmo.tag = "deep" }
        let stored = ((persist.rows[widget.iden]?["gadgets"] as? [[String:Any]])?.first?["gizmos"] as? [[String:Any]])?.first
        XCTAssertEqual(stored?["tag"] as? String, "deep")
        XCTAssertEqual(gizmo.status, DomainStatus.clean)
    }

    func testDeleteCascades() {
        let widget: Widget = Loom.create()
        let gadget = Gadget(), gizmo = Gizmo()
        Loom.transact {
            widget.gadgets.append(gadget)
            gadget.gizmos.append(gizmo)
        }
        Loom.transact { widget.delete() }
        XCTAssertEqual(gadget.status, DomainStatus.deleted)
        XCTAssertEqual(gizmo.status, DomainStatus.deleted)
        XCTAssertNil(persist.rows[widget.iden])
    }

    func testModeBFreeGraph() {
        let gadget = Gadget()
        gadget.label = "free"
        let gizmo = Gizmo()
        gizmo.tag = "wired"
        gadget.gizmos.append(gizmo)
        XCTAssertTrue(gizmo.parent === gadget)

        let attributes = gadget.unload()
        let clone = Gadget(attributes: attributes)
        clone.load(attributes: attributes)
        XCTAssertFalse(clone === gadget)
        XCTAssertEqual(clone.label, "free")
        XCTAssertEqual(clone.gizmos.first?.tag, "wired")
        XCTAssertTrue(clone.gizmos.first?.parent === clone)
        XCTAssertEqual(clone.gizmos.first?.addedCount ?? -1, 0)
    }

    func testCodablePackableBridge() {
        let widget: Widget = Loom.create()
        Loom.transact { widget.spec = Spec(thrust: 9.81, name: "raptor") }
        let stored = persist.rows[widget.iden]?["spec"] as? String
        XCTAssertNotNil(stored)
        XCTAssertEqual(Spec(stored!), Spec(thrust: 9.81, name: "raptor"))
        basket.clearCache()
        let reloaded: Widget = Loom.selectBy(iden: widget.iden)!
        XCTAssertEqual(reloaded.spec, Spec(thrust: 9.81, name: "raptor"))
    }

    func testWarningStrayStillCommits() {
        let widget: Widget = Loom.create()
        Loom.transact { widget.name = "v1" }
        widget.name = "stray"
        Loom.transact {}
        XCTAssertEqual(persist.rows[widget.iden]?["name"] as? String, "stray")
    }

    func testFailedDeleteRetries() {
        let widget: Widget = Loom.create()
        Loom.transact { widget.name = "doomed" }
        persist.failNextCommit = true
        Loom.transact { widget.delete() }
        XCTAssertNotNil(persist.rows[widget.iden])
        Loom.transact {}
        XCTAssertNil(persist.rows[widget.iden])
    }

    func testReplicate() {
        let gadget = Gadget()
        gadget.label = "original"
        let gizmo = Gizmo()
        gadget.gizmos.append(gizmo)
        let copy = Loom.domain(attributes: gadget.unload(), replicate: true) as! Gadget
        XCTAssertNotEqual(copy.iden, gadget.iden)
        XCTAssertEqual(copy.label, "original")
        XCTAssertEqual(copy.gizmos.count, 1)
        XCTAssertNotEqual(copy.gizmos.first?.iden, gizmo.iden)
        XCTAssertTrue(copy.gizmos.first?.parent === copy)
    }

    func testDirtyUsingAttributesMergesChildren() {
        let widget: Widget = Loom.create()
        let gadget = Gadget()
        Loom.transact {
            widget.gadgets.append(gadget)
            gadget.label = "before"
        }
        var attributes = widget.unload()
        var kids = attributes["gadgets"] as! [[String:Any]]
        kids[0]["label"] = "after"
        attributes["gadgets"] = kids
        attributes["name"] = "merged"
        Loom.transact { widget.dirtyUsingAttributes(attributes) }
        XCTAssertTrue(widget.gadgets.first === gadget)
        XCTAssertEqual(gadget.label, "after")
        XCTAssertEqual(persist.rows[widget.iden]?["name"] as? String, "merged")
    }

    func testInject() {
        basket.discipline = .tolerant
        let attributes: [String:Any] = ["iden": "inj-1", "type": "widget", "name": "beamed", "flightNo": 3]
        let anchor = basket.inject(attributes) as! Widget
        XCTAssertEqual(anchor.name, "beamed")
        Loom.transact {}
        XCTAssertEqual(persist.rows["inj-1"]?["name"] as? String, "beamed")
    }

    func testForkVersColumns() {
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

    func testOnlyKeyClearedOnDelete() {
        basket.associate(type: "widget", only: "name")
        let widget: Widget = Loom.create(only: "solo")
        Loom.transact { widget.name = "solo" }
        Loom.transact { widget.delete() }
        XCTAssertNil(Loom.selectBy(only: "solo") as Widget?)
    }

    func testConcurrentTransacts() {
        DispatchQueue.concurrentPerform(iterations: 16) { i in
            let widget: Widget = Loom.create()
            Loom.transact {
                widget.name = "thread\(i)"
                widget.gadgets.append(Gadget())
            }
        }
        XCTAssertEqual(persist.rows.count, 16)
        XCTAssertTrue(persist.rows.values.allSatisfy { ($0["gadgets"] as? [[String:Any]])?.count == 1 })
    }

    func testConcurrentReadsDuringWrites() {
        let widget: Widget = Loom.create()
        Loom.transact { widget.name = "base" }
        DispatchQueue.concurrentPerform(iterations: 32) { i in
            if i % 2 == 0 {
                Loom.transact { widget.flightNo = i }
            } else {
                let found: Widget? = Loom.selectBy(iden: widget.iden)
                XCTAssertTrue(found === widget)
            }
        }
        XCTAssertEqual(widget.status, DomainStatus.clean)
    }

    func testDateRoundTrip() {
        let widget: Widget = Loom.create()
        let date = Date(timeIntervalSinceReferenceDate: 700000000)
        Loom.transact { widget.when = date }
        basket.clearCache()
        let reloaded: Widget = Loom.selectBy(iden: widget.iden)!
        XCTAssertEqual(Int(reloaded.when.timeIntervalSinceReferenceDate), 700000000)
    }

    func testLegacyNumericDate() {
        let widget: Widget = Loom.create()
        Loom.transact { widget.name = "legacy" }
        persist.rows[widget.iden]?["when"] = "700000000"
        basket.clearCache()
        let reloaded: Widget = Loom.selectBy(iden: widget.iden)!
        XCTAssertEqual(Int(reloaded.when.timeIntervalSinceReferenceDate), 700000000)
    }
}

final class SQLitePersistTests: XCTestCase {
    var persist: SQLitePersist!

    override func setUp() {
        super.setUp()
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("LoomTests-\(UUID().uuidString)")
        persist = SQLitePersist("test", directory: directory)
    }

    func seed(_ iden: String, _ attributes: [String:Any]) {
        persist.transact { () -> (Bool) in
            persist.store(iden: iden, attributes: attributes)
            return true
        }
    }

    func testRollbackDiscardsWrites() {
        seed("keep", ["iden":"keep", "type":"widget", "name":"safe"])
        let committed = persist.transact { () -> (Bool) in
            persist.store(iden: "keep", attributes: ["iden":"keep", "type":"widget", "name":"clobbered"])
            persist.store(iden: "new", attributes: ["iden":"new", "type":"widget"])
            return false
        }
        XCTAssertFalse(committed)
        XCTAssertEqual(persist.attributes(iden: "keep")?["name"] as? String, "safe")
        XCTAssertNil(persist.attributes(iden: "new"))
        seed("after", ["iden":"after", "type":"widget"])
        XCTAssertNotNil(persist.attributes(iden: "after"))
    }

    func testRollbackRestoresDeletes() {
        seed("a", ["iden":"a", "type":"widget", "name":"survivor"])
        persist.transact { () -> (Bool) in
            persist.delete(iden: "a")
            return false
        }
        XCTAssertEqual(persist.attributes(iden: "a")?["name"] as? String, "survivor")
    }

    func testDollarQueriesAndCount() {
        seed("a", ["iden":"a", "type":"widget", "name":"Starlink", "flightNo":101])
        seed("b", ["iden":"b", "type":"widget", "flightNo":99])

        let big = persist.select(type: "widget", where: "$flightNo > ?", params: [100])
        XCTAssertEqual(big.count, 1)
        XCTAssertEqual(big.first?["iden"] as? String, "a")

        let ordered = persist.select(type: "widget", where: "ORDER BY $flightNo DESC", params: [])
        XCTAssertEqual(ordered.map { $0["iden"] as! String }, ["a", "b"])

        XCTAssertEqual(persist.count(type: "widget", where: "", params: []), 2)
        XCTAssertEqual(persist.count(type: "widget", where: "$name LIKE ?", params: ["Star%"]), 1)

        let missing = persist.select(where: "name", is: nil, type: "widget")
        XCTAssertEqual(missing.first?["iden"] as? String, "b")

        XCTAssertEqual(persist.selectOne(where: "name", is: "Starlink", type: "widget")?["iden"] as? String, "a")
    }
}
