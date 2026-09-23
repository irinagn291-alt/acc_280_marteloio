import Foundation

/// Role: Chart. Immutable paint model. The collection view never folds.
struct ChartCanvasSnapshot: Equatable, Sendable {
    var gridSize: Int
    var reachRate: Int
    var islands: [Island]
    var rhumbs: [Rhumb]
    var run: Run?
    var phase: FoldOutcome
    var hatches: Set<Island.ID>
    var reachable: Set<Island.ID>
    var landfalls: Set<Island.ID>
    var pages: [Island.ID: Int]
    var bookCount: Int

    static let empty = ChartCanvasSnapshot(
        gridSize: 4,
        reachRate: ReachCost.defaultPagesPerCell,
        islands: [],
        rhumbs: [],
        run: nil,
        phase: .moored,
        hatches: [],
        reachable: [],
        landfalls: [],
        pages: [:],
        bookCount: 0
    )

    static func make(record: ChartRecord, hatches: Set<Island.ID>) -> ChartCanvasSnapshot {
        let reachableIDs = Set(record.reachableIslands(hatches: hatches).map(\.id))
        let landfallIDs = Set(record.islands.compactMap { record.hasLandfall(on: $0.id) ? $0.id : nil })
        var pages: [Island.ID: Int] = [:]
        for island in record.islands {
            pages[island.id] = record.pagesOnIsland(island.id)
        }
        return ChartCanvasSnapshot(
            gridSize: record.gridSize,
            reachRate: record.reachRate,
            islands: record.islands,
            rhumbs: record.rhumbs.sorted { $0.pair.low.uuidString < $1.pair.low.uuidString },
            run: record.run,
            phase: record.phase,
            hatches: hatches,
            reachable: reachableIDs,
            landfalls: landfallIDs,
            pages: pages,
            bookCount: record.books.count
        )
    }

    func item(at index: Int) -> IslandItem? {
        guard islands.indices.contains(index) else { return nil }
        return item(for: islands[index])
    }

    func item(for island: Island) -> IslandItem {
        let origin = run?.originIslandID
        let cost: Int?
        if let origin, let source = islands.first(where: { $0.id == origin }), island.id != origin {
            cost = ReachCost.pages(between: source, and: island, onGrid: reachRate)
        } else {
            cost = nil
        }
        return IslandItem(
            island: island,
            pages: pages[island.id] ?? 0,
            state: plateState(for: island.id),
            reachCost: reachable.contains(island.id) ? cost : nil,
            runRemainder: origin == island.id ? run?.remainder : nil,
            hasLandfall: landfalls.contains(island.id)
        )
    }

    func plateState(for id: Island.ID) -> IslandPlateState {
        if run?.originIslandID == id, phase == .hailed {
            return .hailed
        }
        if reachable.contains(id) {
            return .solid
        }
        return .hatched
    }
}

/// Role: Chart. One island plate. Solid, hatched and hailed are never colour alone.
struct IslandItem: Equatable, Sendable {
    var island: Island
    var pages: Int
    var state: IslandPlateState
    var reachCost: Int?
    var runRemainder: Int?
    var hasLandfall: Bool
}

enum IslandPlateState: String, Equatable, Sendable {
    case hailed
    case solid
    case hatched
}
