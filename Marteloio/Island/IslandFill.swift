import Foundation

/// Role: Island. Family reading_board tile math. Home still spends a Run; this scores pages into tiles.
enum IslandFill {
    static let pagesPerTile = 10
    static let tilesPerIsland = 8

    /// tile = min(totalPages/10, totalTiles−1)
    static func tile(totalPages: Int, totalTiles: Int = tilesPerIsland) -> Int {
        let pages = max(0, totalPages)
        let tiles = max(1, totalTiles)
        return min(pages / pagesPerTile, tiles - 1)
    }

    /// pages from minutes × pace
    static func pages(fromMinutes minutes: Int, pace: Double) -> Int {
        let safeMinutes = max(0, minutes)
        let safePace = max(0, pace)
        return max(0, Int((Double(safeMinutes) * safePace).rounded()))
    }

    /// Island unlock + lighthouse on first reach.
    static func unlocksOnFirstReach(previousPages: Int, addedPages: Int) -> Bool {
        previousPages <= 0 && previousPages + addedPages > 0
    }

    static func lightsLighthouseOnFirstReach(previousPages: Int, addedPages: Int) -> Bool {
        unlocksOnFirstReach(previousPages: previousPages, addedPages: addedPages)
    }
}
