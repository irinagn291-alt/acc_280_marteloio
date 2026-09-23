import Foundation

/// Role: Marks. An over-cost Bear hatches that island for the session and keeps the Run.
struct LuffMark: Identifiable, Codable, Equatable, Sendable {
    var id: UUID
    var daykey: Int
    var islandID: Island.ID
    var cost: Int
    var remainder: Int
    var hatchedForSession: Bool
}
