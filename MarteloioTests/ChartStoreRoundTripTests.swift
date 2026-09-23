import XCTest
@testable import Marteloio

final class ChartStoreRoundTripTests: XCTestCase {
    private var directory: URL!
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var calendar: Calendar!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        suiteName = "mrt.test.\(UUID().uuidString)"
        defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        calendar = Self.utcCalendar()
    }

    override func tearDownWithError() throws {
        if let directory {
            try? FileManager.default.removeItem(at: directory)
        }
        if let suiteName {
            defaults?.removePersistentDomain(forName: suiteName)
        }
        directory = nil
        defaults = nil
        suiteName = nil
    }

    func test_roundTrip_reloadPreservesRunAndRhumb() async throws {
        var seeded = DemoSeed.makeRecord(now: Date(timeIntervalSince1970: 1_746_000_000), calendar: calendar)
        seeded.phase = .moored
        seeded.run = nil
        try ChartVault(directory: directory, defaults: defaults).save(seeded)

        let store = makeStore()
        let first = await store.load(plantDemo: false)
        XCTAssertNil(first.1)
        XCTAssertEqual(first.0.phase, .moored)

        let hailed = await store.apply(
            .hail(bookID: DemoSeed.harborLightID, pages: 60, minutes: 40),
            now: Date(timeIntervalSince1970: 1_746_000_000),
            flushImmediately: true
        )
        XCTAssertEqual(hailed.outcome, .hailed)
        let borne = await store.apply(
            .bear(islandID: DemoSeed.historyID),
            now: Date(timeIntervalSince1970: 1_746_000_000),
            flushImmediately: true
        )
        XCTAssertTrue(borne.accepted)

        let relaunched = makeStore()
        let again = await relaunched.load(plantDemo: false)
        XCTAssertNil(again.1)
        XCTAssertEqual(again.0.run?.remainder, 20)
        XCTAssertEqual(again.0.rhumb(joining: DemoSeed.fictionID, DemoSeed.historyID)?.weight, 1)
        XCTAssertNotNil(defaults.data(forKey: ChartKey.record))
        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.appendingPathComponent("chart.json").path))
    }

    func test_corruptSnapshotFallsBackToBackup() async throws {
        let store = makeStore()
        let seed = DemoSeed.makeRecord(now: Date(timeIntervalSince1970: 1_746_000_000), calendar: calendar)
        try ChartVault(directory: directory, defaults: defaults).save(seed)
        _ = await store.load(plantDemo: false)

        if let good = defaults.data(forKey: ChartKey.record) {
            defaults.set(good, forKey: ChartKey.backup)
        }
        let file = directory.appendingPathComponent("chart.json")
        let backup = directory.appendingPathComponent("chart.json.backup")
        if FileManager.default.fileExists(atPath: file.path) {
            try? FileManager.default.removeItem(at: backup)
            try FileManager.default.copyItem(at: file, to: backup)
        }
        defaults.set(Data("{not-json".utf8), forKey: ChartKey.record)
        try Data("{not-json".utf8).write(to: file)

        let loaded = await makeStore().load(plantDemo: false)
        XCTAssertEqual(loaded.1, .recoveredFromBackup)
        XCTAssertEqual(loaded.0.run?.remainder, 60)
        XCTAssertEqual(loaded.0.books.first?.id, DemoSeed.harborLightID)
    }

    func test_corruptSnapshotWithoutBackupStartsFreshChart() async throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defaults.set(Data("nope".utf8), forKey: ChartKey.record)
        try Data("nope".utf8).write(to: directory.appendingPathComponent("chart.json"))
        let loaded = await makeStore().load(plantDemo: false)
        XCTAssertEqual(loaded.1, .startedFresh)
        XCTAssertTrue(loaded.0.islands.isEmpty)
        XCTAssertEqual(loaded.0.phase, .moored)
    }

    func test_codecSwitchesOnSchemaVersion() throws {
        let data = try ChartCodec.encode(DemoSeed.makeRecord())
        let decoded = try ChartCodec.decode(data)
        XCTAssertEqual(decoded.schemaVersion, 1)
        XCTAssertEqual(decoded.islands.count, 6)
        XCTAssertTrue(decoded.onboardingComplete)

        let future = Data("{\"schemaVersion\":99}".utf8)
        XCTAssertThrowsError(try ChartCodec.decode(future)) { error in
            XCTAssertEqual(error as? ChartCodec.Failure, .unsupportedSchema(99))
        }
        XCTAssertThrowsError(try ChartCodec.decode(Data("[]".utf8))) { error in
            XCTAssertEqual(error as? ChartCodec.Failure, .corrupt)
        }
    }

    func test_resetAllDataClearsSnapshotAndFiles() async throws {
        let store = makeStore()
        try ChartVault(directory: directory, defaults: defaults).save(DemoSeed.makeRecord())
        _ = await store.load(plantDemo: false)
        await store.resetAllData()
        let loaded = await store.load(plantDemo: false)
        XCTAssertTrue(loaded.0.books.isEmpty)
        XCTAssertEqual(loaded.0.phase, .moored)
        XCTAssertNil(defaults.data(forKey: ChartKey.record))
        XCTAssertNil(defaults.data(forKey: ChartKey.backup))
        let leftovers = (try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        )) ?? []
        XCTAssertTrue(leftovers.filter { $0.pathExtension == "json" }.isEmpty)
    }

    func test_catalogCacheWritesAreExcludedFromBackup() async throws {
        let store = makeStore()
        _ = await store.load(plantDemo: false)
        let title = CatalogTitle(
            isbn: "9780141439518",
            title: "Harbor Light",
            author: "North Binding",
            genreHint: "Fiction",
            pageCount: 312
        )
        await store.rememberCatalog([title])
        let cached = await store.cachedCatalog()
        XCTAssertEqual(cached.first?.title, "Harbor Light")
        let url = directory.appendingPathComponent("catalog-cache.json")
        let loaded = try url.resourceValues(forKeys: [.isExcludedFromBackupKey])
        XCTAssertEqual(loaded.isExcludedFromBackup, true)
    }

    #if targetEnvironment(simulator)
    func test_simulatorSeedWritesOnce() async throws {
        let store = makeStore()
        let now = Date(timeIntervalSince1970: 1_746_000_000)
        let first = await store.seedDemoIfNeeded(now: now)
        let second = await store.seedDemoIfNeeded(now: now)
        XCTAssertNil(second)
        XCTAssertEqual(first?.books.count, 3)
        XCTAssertTrue(first?.onboardingComplete ?? false)
        XCTAssertEqual(first?.run?.remainder, 60)
        XCTAssertFalse(first?.reachableIslands().isEmpty ?? true)
        XCTAssertTrue(defaults.bool(forKey: ChartKey.demo))
        XCTAssertNotNil(defaults.data(forKey: ChartKey.record))
    }
    #endif

    private func makeStore() -> ChartStore {
        ChartStore(
            directory: directory,
            suiteName: suiteName,
            calendar: calendar,
            writeDelayNanoseconds: 0
        )
    }

    private static func utcCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        calendar.locale = Locale(identifier: "en_US_POSIX")
        return calendar
    }
}
