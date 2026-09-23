import Foundation

/// Role: Marks. A legal Bear inks or thickens a Rhumb and spends the Run.
struct RhumbMark: Identifiable, Codable, Equatable, Sendable {
    var id: UUID
    var daykey: Int
    var fromIsland: Island.ID
    var toIsland: Island.ID
    var cost: Int
    var weightAfter: Int
}
