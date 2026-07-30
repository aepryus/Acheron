import XCTest
@testable import Acheron

final class EraTests: XCTestCase {
    func testEraAnnouncement() {
#if Weave
        print("[era] Weave — macro-dialect suite active (full coverage)")
#else
        print("[era] classic — this run covers the classic dialect only; the Weave suite (50+ tests) requires: swift test --traits Weave")
#endif
    }
}
