import XCTest
@testable import Marteloio

final class RhumbThickenTests: XCTestCase {
    func test_secondBearOnTheSamePairThickensInsteadOfDuplicating() {
        var record = DemoSeed.makeRecord()
        record.run?.remainder = 80
        record.run?.startedPages = 80
        let first = ChartFold.bear(to: DemoSeed.historyID, record: record, hatches: [], daykey: 20_260_419)
        XCTAssertEqual(first.outcome, .hailed)
        XCTAssertEqual(first.record.rhumbs.filter { $0.pair == IslandPair(DemoSeed.fictionID, DemoSeed.historyID) }.count, 1)
        XCTAssertEqual(first.record.rhumb(joining: DemoSeed.fictionID, DemoSeed.historyID)?.weight, 1)

        let second = ChartFold.bear(to: DemoSeed.historyID, record: first.record, hatches: first.hatches, daykey: 20_260_419)
        XCTAssertTrue(second.accepted)
        let pairRhumbs = second.record.rhumbs.filter { $0.pair == IslandPair(DemoSeed.fictionID, DemoSeed.historyID) }
        XCTAssertEqual(pairRhumbs.count, 1)
        XCTAssertEqual(pairRhumbs.first?.weight, 2)
        if case .rhumb(let mark) = second.mark {
            XCTAssertEqual(mark.weightAfter, 2)
            XCTAssertEqual(mark.cost, 40)
        } else {
            XCTFail("expected RhumbMark")
        }
        XCTAssertEqual(second.record.run?.remainder, 0)
        XCTAssertEqual(second.outcome, .bound)
    }

    func test_existingPoetryScienceRhumbIsNotTheFictionHistoryLine() {
        let record = DemoSeed.makeRecord()
        XCTAssertEqual(record.rhumb(joining: DemoSeed.poetryID, DemoSeed.scienceID)?.weight, 2)
        XCTAssertNil(record.rhumb(joining: DemoSeed.fictionID, DemoSeed.historyID))
        XCTAssertEqual(BearingSummaryQuery.thickest(in: record)?.weight, 2)
    }
}
