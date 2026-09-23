import Foundation

/// Role: Fold. The Chart ADT: Moored, Hailed, Bound.
enum FoldOutcome: String, Codable, Equatable, Sendable {
    case moored
    case hailed
    case bound
}

/// Role: Fold. Why a Hail or Bear was refused. The record stays whole.
enum FoldRefusal: Equatable, Sendable {
    case secondHail
    case bearWhileMoored
    case bearWhileBound
    case sameIsland
    case finishedBook
    case unknownBook
    case unknownIsland
    case invalidPages
    case invalidMinutes
    case shoal
    case alreadyLuffed
    case emptyTitle
    case emptyGenre
}

/// Role: Fold. Pure result of (ChartRecord, Intent). Session hatches travel with it.
struct FoldResult: Equatable, Sendable {
    var record: ChartRecord
    var outcome: FoldOutcome
    var mark: Mark?
    var refusal: FoldRefusal?
    var hatches: Set<Island.ID>

    var accepted: Bool { refusal == nil }

    static func refused(
        _ record: ChartRecord,
        _ refusal: FoldRefusal,
        hatches: Set<Island.ID>
    ) -> FoldResult {
        FoldResult(
            record: record,
            outcome: record.phase,
            mark: nil,
            refusal: refusal,
            hatches: hatches
        )
    }
}

/// Role: Fold. Every verb the Chart accepts.
enum ChartIntent: Equatable, Sendable {
    case hail(bookID: Book.ID, pages: Int, minutes: Int)
    case bear(islandID: Island.ID)
    case finish(bookID: Book.ID)
    case moor(Book)
    case renameIsland(id: Island.ID, genre: String)
    case setReachRate(Int)
    case setGridSize(Int)
    case setReminder(ReminderSettings)
    case setPace(Double)
    case completeOnboarding
}
