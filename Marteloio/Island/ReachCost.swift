import Foundation

/// Role: Island. Pages spent to join two islands: rate × Chebyshev cells.
enum ReachCost {
    static let defaultPagesPerCell = 20

    static func pages(between a: GridPoint, and b: GridPoint, onGrid rate: Int) -> Int {
        max(0, rate) * IslandGrid.chebyshev(a, b)
    }

    static func pages(between a: Island, and b: Island, onGrid rate: Int) -> Int {
        pages(between: a.coordinate, and: b.coordinate, onGrid: rate)
    }
}
