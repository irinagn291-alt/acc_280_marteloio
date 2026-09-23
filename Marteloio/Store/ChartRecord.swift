import Foundation

/// Role: Store. One Codable root under mrt.chart.v1. Islands, books, sessions, the Run, rhumbs, marks.
struct ChartRecord: Codable, Equatable, Sendable {
    var schemaVersion: Int
    var gridSize: Int
    var reachRate: Int
    var readingPace: Double
    var islands: [Island]
    var books: [Book]
    var sessions: [Session]
    var run: Run?
    var rhumbs: [Rhumb]
    var marks: [Mark]
    var phase: FoldOutcome
    var reminder: ReminderSettings
    var onboardingComplete: Bool

    static let currentSchema = 1

    static var empty: ChartRecord {
        ChartRecord(
            schemaVersion: currentSchema,
            gridSize: 4,
            reachRate: ReachCost.defaultPagesPerCell,
            readingPace: 1.5,
            islands: [],
            books: [],
            sessions: [],
            run: nil,
            rhumbs: [],
            marks: [],
            phase: .moored,
            reminder: .evening,
            onboardingComplete: false
        )
    }

    var shelf: Shelf { Shelf(books: books) }

    func island(_ id: Island.ID) -> Island? {
        islands.first { $0.id == id }
    }

    func book(_ id: Book.ID) -> Book? {
        books.first { $0.id == id }
    }

    func rhumb(joining a: Island.ID, _ b: Island.ID) -> Rhumb? {
        let pair = IslandPair(a, b)
        return rhumbs.first { $0.pair == pair }
    }

    func pagesOnIsland(_ id: Island.ID) -> Int {
        marks.reduce(0) { total, mark in
            if case .fix(let fix) = mark, fix.islandID == id {
                return total + fix.pages
            }
            return total
        }
    }

    func hasLandfall(on id: Island.ID) -> Bool {
        marks.contains { mark in
            if case .landfall(let landfall) = mark {
                return landfall.islandID == id
            }
            return false
        }
    }

    func islandID(matchingGenre raw: String) -> Island.ID? {
        let key = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !key.isEmpty else { return nil }
        return islands.first { $0.genre.lowercased() == key }?.id
    }

    func reachableIslands(hatches: Set<Island.ID> = []) -> [Island] {
        guard phase == .hailed, let run else { return [] }
        return RunLedger.reachable(
            from: run.originIslandID,
            remainder: run.remainder,
            islands: islands,
            hatched: hatches,
            rate: reachRate
        )
    }

    mutating func normalize() {
        if schemaVersion <= 0 {
            schemaVersion = Self.currentSchema
        }
        gridSize = min(8, max(2, gridSize))
        reachRate = min(100, max(1, reachRate))
        if readingPace <= 0 {
            readingPace = 1.5
        }
        if run == nil, phase == .hailed {
            phase = .moored
        }
    }
}

/// Role: Store. Local evening reminder. Nothing leaves the device.
struct ReminderSettings: Codable, Equatable, Sendable {
    var isEnabled: Bool
    var hour: Int
    var minute: Int

    static let evening = ReminderSettings(isEnabled: false, hour: 20, minute: 0)
}

enum ChartKey {
    static let record = "mrt.chart.v1"
    static let backup = "mrt.chart.v1.backup"
    static let demo = "mrt.demo.v1"
}

enum ChartCodec {
    enum Failure: Error, Equatable {
        case unsupportedSchema(Int)
        case corrupt
    }

    static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.keyEncodingStrategy = .useDefaultKeys
        return encoder
    }

    static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        return decoder
    }

    static func encode(_ record: ChartRecord) throws -> Data {
        try encoder().encode(record)
    }

    static func decode(_ data: Data) throws -> ChartRecord {
        let probe: SchemaProbe
        do {
            probe = try decoder().decode(SchemaProbe.self, from: data)
        } catch {
            throw Failure.corrupt
        }
        let version = probe.schemaVersion ?? 1
        guard version == ChartRecord.currentSchema else {
            throw Failure.unsupportedSchema(version)
        }
        do {
            var record = try decoder().decode(ChartRecord.self, from: data)
            record.normalize()
            return record
        } catch {
            throw Failure.corrupt
        }
    }

    private struct SchemaProbe: Decodable {
        var schemaVersion: Int?
    }
}
