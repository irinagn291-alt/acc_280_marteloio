import Foundation

/// Role: Run. Unspent pages of the current Hail. Bear subtracts reach cost.
struct Run: Codable, Equatable, Sendable {
    var originIslandID: Island.ID
    var sessionID: Session.ID
    var remainder: Int
    var startedPages: Int

    var isUnspent: Bool { remainder > 0 }
}
