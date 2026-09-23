import Foundation

/// Role: Store. In-memory ChartRecord. Fold first, then a debounced projection to disk.
/// UI never reads UserDefaults or chart.json.
actor ChartStore {
    private var record: ChartRecord
    private var hatches: Set<Island.ID>
    private var warning: StoreWarning?
    private var lastWriteError: String?

    private let vault: ChartVault
    private let writer: DebouncedSave
    private let calendar: Calendar

    init(
        directory: URL,
        suiteName: String? = nil,
        calendar: Calendar = .current,
        writeDelayNanoseconds: UInt64 = 400_000_000
    ) {
        let defaults = suiteName.flatMap { UserDefaults(suiteName: $0) } ?? .standard
        self.vault = ChartVault(directory: directory, defaults: defaults)
        self.writer = DebouncedSave(nanoseconds: writeDelayNanoseconds)
        self.calendar = calendar
        self.record = .empty
        self.hatches = []
    }

    static func applicationSupportStore() -> ChartStore {
        let directory: URL
        if let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            directory = root.appendingPathComponent("Marteloio", isDirectory: true)
        } else {
            directory = FileManager.default.temporaryDirectory.appendingPathComponent(
                "Marteloio",
                isDirectory: true
            )
        }
        return ChartStore(directory: directory)
    }

    func snapshot() -> ChartRecord {
        record
    }

    func sessionHatches() -> Set<Island.ID> {
        hatches
    }

    func loadWarning() -> StoreWarning? {
        warning
    }

    func writeIssue() -> String? {
        lastWriteError
    }

    func load(plantDemo: Bool = true) async -> (ChartRecord, StoreWarning?) {
        let loaded = vault.load()
        record = loaded.record
        warning = loaded.warning
        hatches = []
        lastWriteError = nil
        #if targetEnvironment(simulator)
        if plantDemo {
            await plantDemoIfNeeded()
        }
        #endif
        return (record, warning)
    }

    @discardableResult
    func apply(
        _ intent: ChartIntent,
        now: Date = Date(),
        flushImmediately: Bool = false
    ) async -> FoldResult {
        let daykey = Daykey.of(now, calendar: calendar)
        let result = ChartFold.apply(intent, to: record, hatches: hatches, daykey: daykey)
        guard result.accepted else { return result }
        record = result.record
        hatches = result.hatches
        if flushImmediately {
            await persistNow()
        } else {
            await schedulePersist()
        }
        return result
    }

    func flush() async {
        await writer.cancelPending()
        do {
            try vault.save(record)
            lastWriteError = nil
        } catch {
            lastWriteError = String(describing: error)
        }
    }

    func handleScenePhaseLeavingActive() async {
        await flush()
    }

    func resetAllData() async {
        await writer.cancelPending()
        record = .empty
        hatches = []
        warning = nil
        lastWriteError = nil
        do {
            try vault.wipe()
        } catch {
            lastWriteError = String(describing: error)
        }
    }

    /// Onboarding and a device-first chart need genre islands before Moor can land.
    func adoptIslandsIfEmpty(_ islands: [Island]) async -> ChartRecord {
        guard record.islands.isEmpty, !islands.isEmpty else { return record }
        record.islands = islands
        await persistNow()
        return record
    }

    func rememberCatalog(_ titles: [CatalogTitle]) async {
        do {
            try vault.saveCatalog(titles)
        } catch {
            lastWriteError = String(describing: error)
        }
    }

    func cachedCatalog() -> [CatalogTitle] {
        vault.loadCatalog()
    }

    func seedDemoIfNeeded(now: Date = Date()) async -> ChartRecord? {
        #if targetEnvironment(simulator)
        if vault.demoPlanted() { return nil }
        record = DemoSeed.makeRecord(now: now, calendar: calendar)
        hatches = []
        vault.markDemoPlanted()
        await persistNow()
        return record
        #else
        return nil
        #endif
    }

    private func plantDemoIfNeeded(now: Date = Date()) async {
        _ = await seedDemoIfNeeded(now: now)
    }

    private func schedulePersist() async {
        await writer.schedule {
            await self.flush()
        }
    }

    private func persistNow() async {
        await flush()
    }
}
