import XCTest
@testable import Marteloio

final class MarteloioTests: XCTestCase {
    func test_appModuleImports() {
        XCTAssertEqual(String(describing: MarteloioApp.self), "MarteloioApp")
    }
}
