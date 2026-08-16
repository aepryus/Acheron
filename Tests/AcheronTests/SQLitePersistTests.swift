//
//  SQLitePersistTests.swift
//  Acheron
//

#if !os(Linux)

import XCTest
import SQLite3
@testable import Acheron

final class SQLitePersistTests: XCTestCase {
    var persist: SQLitePersist!

    override func setUp() {
        super.setUp()
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("LoomTests-\(UUID().uuidString)")
        persist = SQLitePersist("test", directory: directory)
    }

    private func seed(_ iden: String, _ attributes: [String:Any]) {
        persist.transact { () -> (Bool) in
            persist.store(iden: iden, attributes: attributes)
            return true
        }
    }

// $ dialect =======================================================================================
    func testDollarQueries() {
        seed("a", ["iden":"a", "type":"widget", "name":"Starlink", "flightNo":101])
        seed("b", ["iden":"b", "type":"widget", "flightNo":99])

        let big = persist.select(type: "widget", where: "$flightNo > ?", params: [100])
        XCTAssertEqual(big.map { $0["iden"] as! String }, ["a"])

        let ordered = persist.select(type: "widget", where: "ORDER BY $flightNo DESC", params: [])
        XCTAssertEqual(ordered.map { $0["iden"] as! String }, ["a", "b"])

        let lowercased = persist.select(type: "widget", where: "  order by $flightNo desc", params: [])
        XCTAssertEqual(lowercased.map { $0["iden"] as! String }, ["a", "b"])

        XCTAssertEqual(persist.select(type: "widget", where: "", params: []).count, 2)
        XCTAssertEqual(persist.count(type: "widget", where: "", params: []), 2)
        XCTAssertEqual(persist.count(type: "widget", where: "$name LIKE ?", params: ["Star%"]), 1)

        XCTAssertEqual(persist.select(where: "name", is: nil, type: "widget").first?["iden"] as? String, "b")
        XCTAssertEqual(persist.selectOne(where: "name", is: "Starlink", type: "widget")?["iden"] as? String, "a")
    }

// index hatch =====================================================================================
    func testIndexIsAdoptedByThePlanner() {
        for i in 0..<200 { seed("w\(i)", ["iden":"w\(i)", "type":"widget", "flightNo":i]) }

        func plan() -> String {
            var s: OpaquePointer? = nil
            var detail = ""
            sqlite3_prepare_v2(persist.db, "EXPLAIN QUERY PLAN SELECT JSON FROM Document WHERE Type=? AND json_extract(JSON,'$.flightNo')>?", -1, &s, nil)
            while sqlite3_step(s) == SQLITE_ROW {
                if let chars = sqlite3_column_text(s, 3) { detail += String(cString: chars) }
            }
            sqlite3_finalize(s)
            return detail
        }

        XCTAssertFalse(plan().contains("Document_widget_flightNo"))
        persist.index(type: "widget", field: "flightNo")
        XCTAssertTrue(plan().contains("Document_widget_flightNo"))
        XCTAssertEqual(persist.select(type: "widget", where: "$flightNo > ?", params: [197]).count, 2)
    }

// guards ==========================================================================================
    func testFieldNamesAreCode() {
        seed("a", ["iden":"a", "type":"widget", "name":"safe"])
        XCTAssertNil(persist.selectOne(where: "name') = '' OR 1=1 --", is: "x", type: "widget"))
        XCTAssertEqual(persist.select(where: "bad'field", is: "x", type: "widget").count, 0)
        persist.index(type: "widget; DROP TABLE Document", field: "flightNo")
        XCTAssertEqual(persist.count(type: "widget", where: "", params: []), 1)
        XCTAssertEqual(persist.selectOne(where: "name", is: "safe", type: "widget")?["iden"] as? String, "a")
    }
    func testPoisonedDocumentIsSkippedNotSwallowed() {
        seed("good", ["iden":"good", "type":"widget", "name":"healthy"])
        persist.transact { () -> (Bool) in
            persist.store(iden: "bad", attributes: ["iden":"bad", "type":"widget", "ratio":Double.nan])
            return true
        }
        XCTAssertNil(persist.attributes(iden: "bad"))
        XCTAssertEqual(persist.attributes(iden: "good")?["name"] as? String, "healthy")
    }

// transactions ====================================================================================
    func testRollbackDiscardsWritesAndRestoresDeletes() {
        seed("keep", ["iden":"keep", "type":"widget", "name":"safe"])
        let committed = persist.transact { () -> (Bool) in
            persist.store(iden: "keep", attributes: ["iden":"keep", "type":"widget", "name":"clobbered"])
            persist.store(iden: "new", attributes: ["iden":"new", "type":"widget"])
            persist.delete(iden: "keep")
            return false
        }
        XCTAssertFalse(committed)
        XCTAssertEqual(persist.attributes(iden: "keep")?["name"] as? String, "safe")
        XCTAssertNil(persist.attributes(iden: "new"))

        seed("after", ["iden":"after", "type":"widget"])
        XCTAssertNotNil(persist.attributes(iden: "after"))
    }
}

#endif
