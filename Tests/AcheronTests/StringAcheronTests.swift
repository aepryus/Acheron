//
//  StringAcheronTests.swift
//  Acheron
//
//  Created by Joe Charlier on 7/28/26.
//  Copyright © 2026 Aepryus Software. All rights reserved.
//

import XCTest
@testable import Acheron

// A target that declares no sources fails package resolution outright, which
// surfaces as "Missing package product" in whichever dependent Xcode looks at
// next.  Keep at least one test here.
final class StringAcheronTests: XCTestCase {
    func testSubscripts() {
        XCTAssertEqual("aether"[0], "a")
        XCTAssertEqual("aether"[1...3], "eth")     // inclusive both ends
        XCTAssertEqual("aether"[2...], "ther")
        XCTAssertEqual("aether"[...2], "aet")      // inclusive of the bound
        XCTAssertEqual("aether"[..<3], "aet")      // ..<b matches ...b-1
    }
    func testLoc() {
        XCTAssertEqual("Local::aether01".loc(of: "::"), 5)
        XCTAssertEqual("a/b/c".lastLoc(of: "/"), 3)
        XCTAssertNil("Oovium".loc(of: "::"))
    }
    func testCapitalize() {
        XCTAssertEqual("oovium".capitalize, "Oovium")
        XCTAssertEqual("".capitalize, "")
    }
    func testLocalizedFallsBackToTheKey() {
        // No bundle in this target defines it, so .localized must return the key
        // rather than an empty string — the behaviour every menu title relies on.
        XCTAssertEqual("a key no bundle defines".localized, "a key no bundle defines")
    }
}
