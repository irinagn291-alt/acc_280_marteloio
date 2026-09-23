import XCTest
@testable import Marteloio

/// Family reading_board invariant:
/// 10 pages/tile, 8 tiles/island.
/// tile = min(totalPages/10, totalTiles−1).
/// Island unlock + lighthouse on first reach.
/// pages from minutes × pace.
final class FamilyInvariantTests: XCTestCase {
    func test_familyInvariant_tileFromTotalPagesAndPaceUnlocksIsland() {
        XCTAssertEqual(IslandFill.pagesPerTile, 10)
        XCTAssertEqual(IslandFill.tilesPerIsland, 8)

        XCTAssertEqual(IslandFill.tile(totalPages: 0, totalTiles: 8), 0)
        XCTAssertEqual(IslandFill.tile(totalPages: 9, totalTiles: 8), 0)
        XCTAssertEqual(IslandFill.tile(totalPages: 10, totalTiles: 8), 1)
        XCTAssertEqual(IslandFill.tile(totalPages: 70, totalTiles: 8), 7)
        XCTAssertEqual(IslandFill.tile(totalPages: 80, totalTiles: 8), 7)
        XCTAssertEqual(IslandFill.tile(totalPages: 999, totalTiles: 8), 7)

        XCTAssertEqual(IslandFill.pages(fromMinutes: 40, pace: 1.5), 60)
        XCTAssertEqual(IslandFill.pages(fromMinutes: 0, pace: 2), 0)

        XCTAssertTrue(IslandFill.unlocksOnFirstReach(previousPages: 0, addedPages: 10))
        XCTAssertTrue(IslandFill.lightsLighthouseOnFirstReach(previousPages: 0, addedPages: 10))
        XCTAssertFalse(IslandFill.unlocksOnFirstReach(previousPages: 10, addedPages: 10))
        XCTAssertFalse(IslandFill.lightsLighthouseOnFirstReach(previousPages: 10, addedPages: 10))

        let seed = DemoSeed.makeRecord()
        let totalPages = seed.pagesOnIsland(DemoSeed.fictionID)
        let totalTiles = IslandFill.tilesPerIsland
        XCTAssertEqual(IslandFill.tile(totalPages: totalPages, totalTiles: totalTiles), 6)
        XCTAssertTrue(IslandFill.unlocksOnFirstReach(previousPages: 0, addedPages: totalPages))
    }
}
