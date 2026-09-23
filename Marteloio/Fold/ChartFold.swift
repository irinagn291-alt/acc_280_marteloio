import Foundation

/// Role: Fold. Pure (ChartRecord, Intent) → (ChartRecord, Mark). Views never fold.
enum ChartFold {
    static func apply(
        _ intent: ChartIntent,
        to record: ChartRecord,
        hatches: Set<Island.ID>,
        daykey: Int
    ) -> FoldResult {
        switch intent {
        case .hail(let bookID, let pages, let minutes):
            return hail(bookID: bookID, pages: pages, minutes: minutes, record: record, daykey: daykey)
        case .bear(let islandID):
            return bear(to: islandID, record: record, hatches: hatches, daykey: daykey)
        case .finish(let bookID):
            return finish(bookID: bookID, record: record, hatches: hatches, daykey: daykey)
        case .moor(let book):
            return moor(book, record: record, hatches: hatches)
        case .renameIsland(let id, let genre):
            return rename(id: id, genre: genre, record: record, hatches: hatches)
        case .setReachRate(let rate):
            return setReachRate(rate, record: record, hatches: hatches)
        case .setGridSize(let size):
            return setGridSize(size, record: record, hatches: hatches)
        case .setReminder(let reminder):
            var next = record
            next.reminder = reminder
            return accepted(next, mark: nil, hatches: hatches)
        case .setPace(let pace):
            var next = record
            next.readingPace = max(0.1, pace)
            return accepted(next, mark: nil, hatches: hatches)
        case .completeOnboarding:
            var next = record
            next.onboardingComplete = true
            return accepted(next, mark: nil, hatches: hatches)
        }
    }

    /// Hail writes a Run as the pages of this session and seats a Fix, folding Moored (or Bound) to Hailed.
    static func hail(
        bookID: Book.ID,
        pages: Int,
        minutes: Int,
        record: ChartRecord,
        daykey: Int
    ) -> FoldResult {
        if record.phase == .hailed {
            return .refused(record, .secondHail, hatches: [])
        }
        guard pages > 0 else {
            return .refused(record, .invalidPages, hatches: [])
        }
        guard minutes >= 0 else {
            return .refused(record, .invalidMinutes, hatches: [])
        }
        guard let book = record.book(bookID) else {
            return .refused(record, .unknownBook, hatches: [])
        }
        guard !book.isFinished else {
            return .refused(record, .finishedBook, hatches: [])
        }
        guard let island = record.island(book.islandID) else {
            return .refused(record, .unknownIsland, hatches: [])
        }

        let session = Session(
            bookID: book.id,
            islandID: island.id,
            pages: pages,
            minutes: minutes,
            daykey: daykey
        )
        let fix = FixMark(
            id: UUID(),
            daykey: daykey,
            islandID: island.id,
            bookID: book.id,
            sessionID: session.id,
            pages: pages,
            minutes: minutes
        )
        var next = record
        next.sessions.append(session)
        next.marks.append(.fix(fix))
        next.run = Run(
            originIslandID: island.id,
            sessionID: session.id,
            remainder: pages,
            startedPages: pages
        )
        next.phase = .hailed
        settlePhase(&next, hatches: [])
        return accepted(next, mark: .fix(fix), hatches: [])
    }

    /// Bear writes a RhumbMark when the tap is distinct and the cost is at or under the Run.
    static func bear(
        to islandID: Island.ID,
        record: ChartRecord,
        hatches: Set<Island.ID>,
        daykey: Int
    ) -> FoldResult {
        if Shoal.blocksBear(record) {
            return .refused(record, .shoal, hatches: hatches)
        }
        switch record.phase {
        case .moored:
            return .refused(record, .bearWhileMoored, hatches: hatches)
        case .bound:
            return .refused(record, .bearWhileBound, hatches: hatches)
        case .hailed:
            break
        }
        guard let run = record.run else {
            return .refused(record, .bearWhileMoored, hatches: hatches)
        }
        guard let origin = record.island(run.originIslandID) else {
            return .refused(record, .unknownIsland, hatches: hatches)
        }
        guard let target = record.island(islandID) else {
            return .refused(record, .unknownIsland, hatches: hatches)
        }
        guard target.id != origin.id else {
            return .refused(record, .sameIsland, hatches: hatches)
        }
        if hatches.contains(target.id) {
            return .refused(record, .alreadyLuffed, hatches: hatches)
        }

        let cost = ReachCost.pages(between: origin, and: target, onGrid: record.reachRate)
        if cost > run.remainder {
            return luff(
                target: target,
                cost: cost,
                remainder: run.remainder,
                record: record,
                hatches: hatches,
                daykey: daykey
            )
        }

        return ink(
            from: origin,
            to: target,
            cost: cost,
            run: run,
            record: record,
            hatches: hatches,
            daykey: daykey
        )
    }

    private static func luff(
        target: Island,
        cost: Int,
        remainder: Int,
        record: ChartRecord,
        hatches: Set<Island.ID>,
        daykey: Int
    ) -> FoldResult {
        let mark = LuffMark(
            id: UUID(),
            daykey: daykey,
            islandID: target.id,
            cost: cost,
            remainder: remainder,
            hatchedForSession: true
        )
        var next = record
        next.marks.append(.luff(mark))
        var nextHatches = hatches
        nextHatches.insert(target.id)
        settlePhase(&next, hatches: nextHatches)
        return accepted(next, mark: .luff(mark), hatches: nextHatches)
    }

    private static func ink(
        from origin: Island,
        to target: Island,
        cost: Int,
        run: Run,
        record: ChartRecord,
        hatches: Set<Island.ID>,
        daykey: Int
    ) -> FoldResult {
        var next = record
        var spent = run
        spent.remainder -= cost
        next.run = spent

        let pair = IslandPair(origin.id, target.id)
        let weightAfter: Int
        if let index = next.rhumbs.firstIndex(where: { $0.pair == pair }) {
            next.rhumbs[index].weight += 1
            weightAfter = next.rhumbs[index].weight
        } else {
            let rhumb = Rhumb(
                pair: pair,
                weight: 1,
                bearing: RhumbGeometry.bearing(from: origin.coordinate, to: target.coordinate)
            )
            next.rhumbs.append(rhumb)
            weightAfter = 1
        }

        let mark = RhumbMark(
            id: UUID(),
            daykey: daykey,
            fromIsland: origin.id,
            toIsland: target.id,
            cost: cost,
            weightAfter: weightAfter
        )
        next.marks.append(.rhumb(mark))
        settlePhase(&next, hatches: hatches)
        return accepted(next, mark: .rhumb(mark), hatches: hatches)
    }

    private static func finish(
        bookID: Book.ID,
        record: ChartRecord,
        hatches: Set<Island.ID>,
        daykey: Int
    ) -> FoldResult {
        guard let index = record.books.firstIndex(where: { $0.id == bookID }) else {
            return .refused(record, .unknownBook, hatches: hatches)
        }
        guard !record.books[index].isFinished else {
            return .refused(record, .finishedBook, hatches: hatches)
        }
        var next = record
        next.books[index].isFinished = true
        let mark = Landfall(
            id: UUID(),
            daykey: daykey,
            islandID: next.books[index].islandID,
            bookID: bookID
        )
        next.marks.append(.landfall(mark))
        return accepted(next, mark: .landfall(mark), hatches: hatches)
    }

    private static func moor(
        _ book: Book,
        record: ChartRecord,
        hatches: Set<Island.ID>
    ) -> FoldResult {
        let title = book.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else {
            return .refused(record, .emptyTitle, hatches: hatches)
        }
        guard record.island(book.islandID) != nil else {
            return .refused(record, .unknownIsland, hatches: hatches)
        }
        var next = record
        var incoming = book
        incoming.title = title
        incoming.isbn = IsbnDigits.canonicalize(book.isbn) ?? book.isbn
        if let existing = next.shelf.first(isbn: incoming.isbn),
           let index = next.books.firstIndex(where: { $0.id == existing.id }) {
            incoming.id = existing.id
            incoming.isFinished = existing.isFinished
            next.books[index] = incoming
        } else {
            next.books.append(incoming)
        }
        return accepted(next, mark: nil, hatches: hatches)
    }

    private static func rename(
        id: Island.ID,
        genre: String,
        record: ChartRecord,
        hatches: Set<Island.ID>
    ) -> FoldResult {
        guard let index = record.islands.firstIndex(where: { $0.id == id }) else {
            return .refused(record, .unknownIsland, hatches: hatches)
        }
        guard let renamed = IslandRename.applying(genre, to: record.islands[index]) else {
            return .refused(record, .emptyGenre, hatches: hatches)
        }
        var next = record
        next.islands[index] = renamed
        return accepted(next, mark: nil, hatches: hatches)
    }

    private static func setReachRate(
        _ rate: Int,
        record: ChartRecord,
        hatches: Set<Island.ID>
    ) -> FoldResult {
        var next = record
        next.reachRate = min(100, max(1, rate))
        settlePhase(&next, hatches: hatches)
        return accepted(next, mark: nil, hatches: hatches)
    }

    private static func setGridSize(
        _ size: Int,
        record: ChartRecord,
        hatches: Set<Island.ID>
    ) -> FoldResult {
        var next = record
        next.gridSize = min(8, max(2, size))
        return accepted(next, mark: nil, hatches: hatches)
    }

    /// When the remaining Run cannot pay the cheapest Island still reachable, fold Hailed to Bound.
    static func settlePhase(_ record: inout ChartRecord, hatches: Set<Island.ID>) {
        guard record.phase == .hailed, let run = record.run else { return }
        if Shoal.blocksBear(record) {
            record.phase = .bound
            return
        }
        guard let cheapest = RunLedger.cheapestCost(
            from: run.originIslandID,
            islands: record.islands,
            hatched: hatches,
            rate: record.reachRate
        ) else {
            record.phase = .bound
            return
        }
        if cheapest > run.remainder {
            record.phase = .bound
        } else {
            record.phase = .hailed
        }
    }

    private static func accepted(
        _ record: ChartRecord,
        mark: Mark?,
        hatches: Set<Island.ID>
    ) -> FoldResult {
        FoldResult(
            record: record,
            outcome: record.phase,
            mark: mark,
            refusal: nil,
            hatches: hatches
        )
    }
}
