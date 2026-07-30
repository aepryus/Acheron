#if !Weave && !os(Linux)

import XCTest
@testable import Acheron

class MemoryPersist: Persist {
    var rows: [String:[String:Any]] = [:]
    var kv: [String:String] = [:]
    var failNextCommit: Bool = false

    override func selectAll(type: String) -> [[String:Any]] { rows.values.filter { $0["type"] as? String == type } }
    override func attributes(iden: String) -> [String:Any]? { rows[iden] }
    override func attributes(type: String, only: String) -> [String:Any]? {
        guard let key = typeToOnly[type] else { return nil }
        return rows.values.first { $0["type"] as? String == type && $0[key] as? String == only }
    }
    override func store(iden: String, attributes: [String:Any]) -> Bool { rows[iden] = attributes; return true }
    override func delete(iden: String) -> Bool { rows.removeValue(forKey: iden); return true }
    override func transact(_ closure: ()->(Bool)) -> Bool {
        let snapshot = rows
        let ok = closure() && !failNextCommit
        if !ok { rows = snapshot }
        failNextCommit = false
        return ok
    }
    override func set(key: String, value: String) { kv[key] = value }
    override func get(key: String) -> String? { kv[key] }
}

class Gadget: Domain {
    @objc dynamic var label: String = ""
    override var properties: [String] { super.properties + ["label"] }
}
class Widget: Anchor {
    @objc dynamic var name: String = ""
    @objc dynamic var flightNo: Int = 0
    @objc dynamic var when: Date = Date()
    @objc dynamic var gadgets: [Gadget] = []
    override var properties: [String] { super.properties + ["name", "flightNo", "when"] }
    override var children: [String] { ["gadgets"] }
}

final class LoomTests: XCTestCase {
    var persist: MemoryPersist!
    var basket: Basket!

    override func setUp() {
        super.setUp()
        persist = MemoryPersist("test")
        basket = Basket(persist)
        Loom.basket = basket
        Loom.namespaces = ["AcheronTests"]
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
            widget.add(gadget)
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

    func testAsyncTransact() async {
        let widget: Widget = Loom.create()
        await Loom.transact { widget.name = "awaited" }
        XCTAssertEqual(persist.rows[widget.iden]?["name"] as? String, "awaited")
    }

    func testDelete() {
        let widget: Widget = Loom.create()
        Loom.transact { widget.name = "gone" }
        Loom.transact { widget.delete() }
        XCTAssertNil(persist.rows[widget.iden])
        XCTAssertNil(basket.selectBy(iden: widget.iden))
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

#endif
