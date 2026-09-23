import XCTest
@testable import Marteloio

final class ChartFoldTests: XCTestCase {
    private let daykey = 20_260_419

    func test_hailFromMooredWritesFixAndRun() {
        var record = DemoSeed.makeRecord()
        record.phase = .moored
        record.run = nil
        record.marks.removeAll { if case .fix(let fix) = $0 { return fix.id == DemoSeed.hailFixID } else { return false } }

        let before = record
        let result = ChartFold.hail(
            bookID: DemoSeed.harborLightID,
            pages: 40,
            minutes: 30,
            record: record,
            daykey: daykey
        )

        XCTAssertEqual(before.phase, .moored)
        XCTAssertNil(before.run)
        XCTAssertTrue(result.accepted)
        XCTAssertEqual(result.outcome, .hailed)
        XCTAssertEqual(result.record.run?.remainder, 40)
        XCTAssertEqual(result.record.run?.originIslandID, DemoSeed.fictionID)
        if case .fix(let mark) = result.mark {
            XCTAssertEqual(mark.pages, 40)
            XCTAssertEqual(mark.islandID, DemoSeed.fictionID)
        } else {
            XCTFail("expected FixMark")
        }
        XCTAssertTrue(result.hatches.isEmpty)
        XCTAssertEqual(record.phase, .moored)
    }

    func test_secondHailWhileHailedIsRefused() {
        let record = DemoSeed.makeRecord()
        XCTAssertEqual(record.phase, .hailed)
        let result = ChartFold.apply(
            .hail(bookID: DemoSeed.saltMeridianID, pages: 20, minutes: 10),
            to: record,
            hatches: [],
            daykey: daykey
        )
        XCTAssertEqual(result.refusal, .secondHail)
        XCTAssertEqual(result.record.run?.remainder, 60)
    }

    func test_hailFinishedBookIsRefused() {
        var record = DemoSeed.makeRecord()
        record.phase = .bound
        record.run = nil
        let result = ChartFold.apply(
            .hail(bookID: DemoSeed.quietHarborID, pages: 20, minutes: 10),
            to: record,
            hatches: [],
            daykey: daykey
        )
        XCTAssertEqual(result.refusal, .finishedBook)
    }

    func test_invalidPagesAndUnknownBook() {
        var record = DemoSeed.makeRecord()
        record.phase = .moored
        record.run = nil
        XCTAssertEqual(
            ChartFold.apply(.hail(bookID: DemoSeed.harborLightID, pages: 0, minutes: 10), to: record, hatches: [], daykey: daykey).refusal,
            .invalidPages
        )
        XCTAssertEqual(
            ChartFold.apply(.hail(bookID: DemoSeed.harborLightID, pages: -4, minutes: 10), to: record, hatches: [], daykey: daykey).refusal,
            .invalidPages
        )
        XCTAssertEqual(
            ChartFold.apply(.hail(bookID: UUID(), pages: 20, minutes: 10), to: record, hatches: [], daykey: daykey).refusal,
            .unknownBook
        )
    }

    func test_bearOnMooredIsRefused() {
        var record = DemoSeed.makeRecord()
        record.phase = .moored
        record.run = nil
        let result = ChartFold.bear(to: DemoSeed.historyID, record: record, hatches: [], daykey: daykey)
        XCTAssertEqual(result.refusal, .bearWhileMoored)
    }

    func test_bearSameIslandIsRefused() {
        let record = DemoSeed.makeRecord()
        let result = ChartFold.bear(to: DemoSeed.fictionID, record: record, hatches: [], daykey: daykey)
        XCTAssertEqual(result.refusal, .sameIsland)
    }

    func test_bearPaysCostAndInksRhumb() {
        let record = DemoSeed.makeRecord()
        XCTAssertFalse(record.reachableIslands().isEmpty, "seeded home verb is enabled")
        let result = ChartFold.bear(to: DemoSeed.historyID, record: record, hatches: [], daykey: daykey)
        XCTAssertTrue(result.accepted)
        XCTAssertEqual(result.record.run?.remainder, 20)
        XCTAssertEqual(result.outcome, .bound)
        if case .rhumb(let mark) = result.mark {
            XCTAssertEqual(mark.fromIsland, DemoSeed.fictionID)
            XCTAssertEqual(mark.toIsland, DemoSeed.historyID)
            XCTAssertEqual(mark.cost, 40)
            XCTAssertEqual(mark.weightAfter, 1)
        } else {
            XCTFail("expected RhumbMark")
        }
        XCTAssertNotNil(result.record.rhumb(joining: DemoSeed.fictionID, DemoSeed.historyID))
        XCTAssertEqual(record.rhumbs.count, 1)
    }

    func test_overCostBearWritesLuffAndKeepsRun() {
        let record = DemoSeed.makeRecord()
        var cheap = record
        cheap.run?.remainder = 20
        let result = ChartFold.bear(to: DemoSeed.historyID, record: cheap, hatches: [], daykey: daykey)
        XCTAssertTrue(result.accepted)
        XCTAssertEqual(result.record.run?.remainder, 20)
        XCTAssertTrue(result.hatches.contains(DemoSeed.historyID))
        if case .luff(let mark) = result.mark {
            XCTAssertEqual(mark.islandID, DemoSeed.historyID)
            XCTAssertTrue(mark.hatchedForSession)
            XCTAssertEqual(mark.cost, 40)
        } else {
            XCTFail("expected LuffMark")
        }
    }

    func test_foldMovesHailedToBoundWhenNothingLeftToPay() {
        var record = DemoSeed.makeRecord()
        record.run?.remainder = 40
        let result = ChartFold.bear(to: DemoSeed.historyID, record: record, hatches: [], daykey: daykey)
        XCTAssertEqual(result.outcome, .bound)
        XCTAssertEqual(result.record.run?.remainder, 0)
        if case .rhumb = result.mark {
        } else {
            XCTFail("expected RhumbMark")
        }
    }

    func test_hailWithUnpayableRunFoldsToBound() {
        var record = DemoSeed.makeRecord()
        record.phase = .bound
        record.run = nil
        let result = ChartFold.hail(
            bookID: DemoSeed.harborLightID,
            pages: 10,
            minutes: 8,
            record: record,
            daykey: daykey
        )
        XCTAssertEqual(result.outcome, .bound)
        XCTAssertEqual(result.record.run?.remainder, 10)
    }

    func test_shoalBlocksBear() {
        var record = ChartRecord.empty
        record.islands = [
            Island(id: DemoSeed.fictionID, genre: "Fiction", coordinate: GridPoint(column: 0, row: 0)),
        ]
        record.books = [
            Book(id: DemoSeed.harborLightID, isbn: "9780141439518", title: "Harbor Light", islandID: DemoSeed.fictionID),
        ]
        record.phase = .hailed
        record.run = Run(
            originIslandID: DemoSeed.fictionID,
            sessionID: DemoSeed.hailSessionID,
            remainder: 60,
            startedPages: 60
        )
        let result = ChartFold.bear(to: DemoSeed.historyID, record: record, hatches: [], daykey: daykey)
        XCTAssertEqual(result.refusal, .shoal)
        XCTAssertTrue(Shoal.blocksBear(record))
    }

    func test_finishWritesLandfall() {
        let record = DemoSeed.makeRecord()
        let result = ChartFold.apply(
            .finish(bookID: DemoSeed.harborLightID),
            to: record,
            hatches: [],
            daykey: daykey
        )
        XCTAssertTrue(result.accepted)
        XCTAssertEqual(result.record.book(DemoSeed.harborLightID)?.isFinished, true)
        XCTAssertTrue(result.record.hasLandfall(on: DemoSeed.fictionID))
    }

    func test_architectureKeepsInputRecordIntact() {
        let record = DemoSeed.makeRecord()
        let copy = record
        _ = ChartFold.bear(to: DemoSeed.historyID, record: record, hatches: [], daykey: daykey)
        XCTAssertEqual(record, copy)
        XCTAssertEqual(record.phase, .hailed)
        XCTAssertEqual(record.run?.remainder, 60)
    }
}
