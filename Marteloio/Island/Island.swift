import Foundation

/// Role: Island. One genre plate on the portolan grid. Page totals are derived from FixMarks.
struct Island: Identifiable, Codable, Equatable, Sendable {
    typealias ID = UUID

    var id: ID
    var genre: String
    var coordinate: GridPoint

    init(id: ID = UUID(), genre: String, coordinate: GridPoint) {
        self.id = id
        self.genre = genre
        self.coordinate = coordinate
    }
}

/// Role: Island. Column/row on the fixed chart grid. Row grows south.
struct GridPoint: Hashable, Codable, Equatable, Sendable {
    var column: Int
    var row: Int
}
