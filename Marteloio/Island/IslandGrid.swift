import Foundation

/// Role: Island. Chebyshev metric for reach. One cell is one step, including diagonals.
enum IslandGrid {
    static func chebyshev(_ a: GridPoint, _ b: GridPoint) -> Int {
        max(abs(a.column - b.column), abs(a.row - b.row))
    }

    static func contains(_ point: GridPoint, size: Int) -> Bool {
        (0..<size).contains(point.column) && (0..<size).contains(point.row)
    }
}
