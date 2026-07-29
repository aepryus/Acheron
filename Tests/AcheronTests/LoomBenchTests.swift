import XCTest
@testable import Acheron

final class LoomBenchTests: XCTestCase {
    var persist: MemoryPersist!
    var basket: Basket!

    override func setUp() {
        super.setUp()
        persist = MemoryPersist("bench")
        basket = Basket(persist)
        Loom.basket = basket
        Loom.register([Widget.self, Gadget.self, Gizmo.self])
    }

    func testBenchFieldGets() {
        let widget: Widget = Loom.create()
        Loom.transact { widget.flightNo = 7 }
        var total = 0
        measure {
            for _ in 0..<1_000_000 { total &+= widget.flightNo }
        }
        XCTAssertGreaterThan(total, 0)
    }

    func testBenchFieldSets() {
        let widget: Widget = Loom.create()
        Loom.transact {}
        measure {
            Loom.transact { for i in 0..<100_000 { widget.flightNo = i } }
        }
    }

    func testBenchValueAppends() {
        let widget: Widget = Loom.create()
        Loom.transact {}
        measure {
            Loom.transact { for i in 0..<10_000 { widget.path.append(Vector(Double(i), 0)) } }
        }
    }

    func testBenchChildAppends() {
        measure {
            let widget: Widget = Loom.create()
            Loom.transact { for _ in 0..<1_000 { widget.gadgets.append(Gadget()) } }
        }
    }

    func testBenchCommit() {
        measure {
            Loom.transact {
                for _ in 0..<1_000 {
                    let widget: Widget = Loom.create()
                    widget.name = "bench"
                    for _ in 0..<5 { widget.gadgets.append(Gadget()) }
                }
            }
        }
    }

    func testBenchHydration() {
        Loom.transact {
            for _ in 0..<1_000 {
                let widget: Widget = Loom.create()
                for _ in 0..<5 { widget.gadgets.append(Gadget()) }
            }
        }
        measure {
            basket.clearCache()
            _ = basket.selectAll(Widget.self)
        }
    }
}
