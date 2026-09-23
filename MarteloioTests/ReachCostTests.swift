import XCTest
@testable import Marteloio

final class ReachCostTests: XCTestCase {
    func test_costIsRateTimesChebyshevCells() {
        let origin = GridPoint(column: 0, row: 0)
        let adjacent = GridPoint(column: 1, row: 0)
        let diagonal = GridPoint(column: 1, row: 1)
        let far = GridPoint(column: 2, row: 1)

        XCTAssertEqual(ReachCost.pages(between: origin, and: adjacent, onGrid: 20), 20)
        XCTAssertEqual(ReachCost.pages(between: origin, and: diagonal, onGrid: 20), 20)
        XCTAssertEqual(ReachCost.pages(between: origin, and: far, onGrid: 20), 40)
        XCTAssertEqual(IslandGrid.chebyshev(origin, far), 2)
    }

    func test_seededFictionCanReachHistoryForFortyPages() throws {
        let record = DemoSeed.makeRecord()
        let fiction = try XCTUnwrap(record.island(DemoSeed.fictionID))
        let history = try XCTUnwrap(record.island(DemoSeed.historyID))
        XCTAssertEqual(ReachCost.pages(between: fiction, and: history, onGrid: record.reachRate), 40)
        XCTAssertTrue(record.reachableIslands().contains(where: { $0.id == DemoSeed.historyID }))
    }
}
