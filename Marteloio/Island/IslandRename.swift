import Foundation

/// Role: Island. Genre rename stays on the island; the coordinate never moves.
enum IslandRename {
    static func applying(_ raw: String, to island: Island) -> Island? {
        let name = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }
        var next = island
        next.genre = name
        return next
    }
}
