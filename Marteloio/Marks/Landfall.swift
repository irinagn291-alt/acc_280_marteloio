import Foundation

/// Role: Marks. Finished writes a Landfall. That island keeps a hatched ring.
struct Landfall: Identifiable, Codable, Equatable, Sendable {
    var id: UUID
    var daykey: Int
    var islandID: Island.ID
    var bookID: Book.ID
}
