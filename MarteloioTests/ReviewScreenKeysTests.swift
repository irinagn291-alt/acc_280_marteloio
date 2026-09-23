import XCTest
@testable import Marteloio

final class ReviewScreenKeysTests: XCTestCase {
    func test_parsesTodayLogGoalsAndShelf() {
        XCTAssertEqual(ReviewScreenKeys.parse(["-ReviewScreen", "today"]), .today)
        XCTAssertEqual(ReviewScreenKeys.parse(["app", "-ReviewScreen", "log"]), .log)
        XCTAssertEqual(ReviewScreenKeys.parse(["-ReviewScreen", "goals"]), .goals)
        XCTAssertEqual(ReviewScreenKeys.parse(["-ReviewScreen", "shelf"]), .shelf)
    }

    func test_missingOrUnknownKeyIsNil() {
        XCTAssertNil(ReviewScreenKeys.parse([]))
        XCTAssertNil(ReviewScreenKeys.parse(["-ReviewScreen"]))
        XCTAssertNil(ReviewScreenKeys.parse(["-ReviewScreen", "unknown"]))
        XCTAssertNil(ReviewScreenKeys.parse(["today"]))
    }
}
