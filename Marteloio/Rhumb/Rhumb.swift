import Foundation

/// Role: Rhumb. One unordered pair, one line. A later Bear thickens weight instead of drawing twice.
struct Rhumb: Identifiable, Codable, Equatable, Sendable {
    var pair: IslandPair
    var weight: Int
    var bearing: Bearing

    var id: IslandPair { pair }
}

/// Role: Rhumb. Stable key for an unordered island pair.
struct IslandPair: Hashable, Codable, Equatable, Sendable {
    var low: Island.ID
    var high: Island.ID

    init(_ a: Island.ID, _ b: Island.ID) {
        if a.uuidString <= b.uuidString {
            low = a
            high = b
        } else {
            low = b
            high = a
        }
    }

    func contains(_ id: Island.ID) -> Bool {
        low == id || high == id
    }
}

/// Role: Rhumb. Eight-point rose stored with each inked line.
enum Bearing: String, Codable, Equatable, Sendable, CaseIterable {
    case n
    case ne
    case e
    case se
    case s
    case sw
    case w
    case nw
}
