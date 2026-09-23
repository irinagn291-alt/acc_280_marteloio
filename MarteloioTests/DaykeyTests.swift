import XCTest
@testable import Marteloio

final class DaykeyTests: XCTestCase {
    func test_daykeyUsesStartOfDayInTheGivenCalendar() throws {
        let calendar = Self.utcCalendar()
        let date = Date(timeIntervalSince1970: 1_746_000_000)
        let start = calendar.startOfDay(for: date)
        let parts = calendar.dateComponents([.year, .month, .day], from: start)
        let year = try XCTUnwrap(parts.year)
        let month = try XCTUnwrap(parts.month)
        let day = try XCTUnwrap(parts.day)
        let expected = year * 10_000 + month * 100 + day
        XCTAssertEqual(Daykey.of(date, calendar: calendar), expected)
        XCTAssertEqual(Daykey.of(start, calendar: calendar), expected)
    }

    func test_sameLocalDaySharesAKeyAcrossTheAfternoon() throws {
        let calendar = Self.utcCalendar()
        let morning = Date(timeIntervalSince1970: 1_746_000_000)
        let later = morning.addingTimeInterval(8 * 60 * 60)
        XCTAssertEqual(Daykey.of(morning, calendar: calendar), Daykey.of(later, calendar: calendar))
        let nextMorning = try XCTUnwrap(calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: morning)))
        XCTAssertNotEqual(Daykey.of(morning, calendar: calendar), Daykey.of(nextMorning, calendar: calendar))
    }

    func test_logbookGroupsMarksByDaykey() {
        let record = DemoSeed.makeRecord(now: Date(timeIntervalSince1970: 1_746_000_000), calendar: Self.utcCalendar())
        let groups = LogbookQuery.groups(from: record)
        XCTAssertGreaterThanOrEqual(groups.count, 2)
        XCTAssertEqual(LogbookQuery.pagesPerIsland(from: record)[DemoSeed.fictionID], 60)
        XCTAssertEqual(LogbookQuery.rhumbCountPerPair(from: record)[IslandPair(DemoSeed.poetryID, DemoSeed.scienceID)], 2)
    }

    private static func utcCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        calendar.locale = Locale(identifier: "en_US_POSIX")
        return calendar
    }
}
