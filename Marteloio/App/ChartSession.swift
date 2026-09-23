import Foundation
import Observation
import UIKit

/// Role: App. Presentation seam. Views fold through this type, never through ChartVault.
@MainActor
@Observable
final class ChartSession {
    var record: ChartRecord = .empty
    var hatches: Set<Island.ID> = []
    var warning: StoreWarning?
    var writeIssue: String?
    var isReady = false
    var presented: ChartSurface?
    var hailBook: Book?
    var isReplayingOnboarding = false
    var lastRefusal: FoldRefusal?
    var lastMark: Mark?
    var isWorking = false
    var didConsumeReview = false

    let catalog: CatalogClient
    private let store: ChartStore

    init(store: ChartStore = .applicationSupportStore(), catalog: CatalogClient = CatalogClient()) {
        self.store = store
        self.catalog = catalog
    }

    var canvas: ChartCanvasSnapshot {
        ChartCanvasSnapshot.make(record: record, hatches: hatches)
    }

    var shouldOnboard: Bool {
        isReplayingOnboarding || (isReady && !record.onboardingComplete)
    }

    func start() async {
        let loaded = await store.load(plantDemo: true)
        record = loaded.0
        warning = loaded.1
        hatches = await store.sessionHatches()
        writeIssue = await store.writeIssue()
        record = await store.adoptIslandsIfEmpty(StarterChart.islands())
        let cached = await store.cachedCatalog()
        for title in cached {
            await catalog.remember(title)
        }
        isReady = true
        consumeReviewLaunch()
    }

    @discardableResult
    func apply(_ intent: ChartIntent, celebrate: Bool = false) async -> FoldResult {
        isWorking = true
        lastRefusal = nil
        let result = await store.apply(intent)
        record = await store.snapshot()
        hatches = result.hatches
        lastRefusal = result.refusal
        lastMark = result.mark
        writeIssue = await store.writeIssue()
        isWorking = false
        if result.accepted, celebrate {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        return result
    }

    func flush() async {
        await store.handleScenePhaseLeavingActive()
        writeIssue = await store.writeIssue()
    }

    func resetAll() async {
        await store.resetAllData()
        record = await store.adoptIslandsIfEmpty(StarterChart.islands())
        hatches = []
        warning = nil
        writeIssue = await store.writeIssue()
        presented = nil
        hailBook = nil
        lastMark = nil
        lastRefusal = nil
    }

    func rememberCatalog(_ titles: [CatalogTitle]) async {
        await store.rememberCatalog(titles)
    }

    func ensureIslands() async {
        record = await store.adoptIslandsIfEmpty(StarterChart.islands())
    }

    func consumeReviewLaunch() {
        guard record.onboardingComplete, !didConsumeReview else { return }
        didConsumeReview = true
        switch ReviewScreenKeys.parse(from: .processInfo) {
        case .today, .none:
            break
        case .log:
            presented = .logbook
        case .goals:
            presented = .settings
        case .shelf:
            presented = .shelf
        }
    }
}

/// Role: App. Sheet stack destinations over the locked chart. Not tabs.
enum ChartSurface: String, Identifiable, Equatable, Sendable {
    case shelf
    case logbook
    case settings
    case reach

    var id: String { rawValue }
}
