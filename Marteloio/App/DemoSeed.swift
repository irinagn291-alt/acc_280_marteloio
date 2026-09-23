import Foundation

/// Role: App. Simulator seed only. Hailed Fiction with a 60-page Run so the first tap can ink a Rhumb.
enum DemoSeed {
    static let fictionID = makeID("aaaaaaaa-0001-4000-8000-000000000001")
    static let historyID = makeID("aaaaaaaa-0001-4000-8000-000000000002")
    static let poetryID = makeID("aaaaaaaa-0001-4000-8000-000000000003")
    static let scienceID = makeID("aaaaaaaa-0001-4000-8000-000000000004")
    static let travelID = makeID("aaaaaaaa-0001-4000-8000-000000000005")
    static let mysteryID = makeID("aaaaaaaa-0001-4000-8000-000000000006")

    static let harborLightID = makeID("bbbbbbbb-0001-4000-8000-000000000001")
    static let saltMeridianID = makeID("bbbbbbbb-0001-4000-8000-000000000002")
    static let quietHarborID = makeID("bbbbbbbb-0001-4000-8000-000000000003")

    static let hailSessionID = makeID("cccccccc-0001-4000-8000-000000000001")
    static let hailFixID = makeID("dddddddd-0001-4000-8000-000000000001")
    static let priorFixID = makeID("dddddddd-0001-4000-8000-000000000002")
    static let priorRhumbID = makeID("dddddddd-0001-4000-8000-000000000003")
    static let priorLandfallID = makeID("dddddddd-0001-4000-8000-000000000004")

    static func makeRecord(now: Date = Date(), calendar: Calendar = .current) -> ChartRecord {
        let today = Daykey.of(now, calendar: calendar)
        let prior = priorDaykey(from: today)

        let islands = [
            Island(id: fictionID, genre: "Fiction", coordinate: GridPoint(column: 0, row: 0)),
            Island(id: historyID, genre: "History", coordinate: GridPoint(column: 0, row: 2)),
            Island(id: poetryID, genre: "Poetry", coordinate: GridPoint(column: 2, row: 0)),
            Island(id: scienceID, genre: "Science", coordinate: GridPoint(column: 2, row: 2)),
            Island(id: travelID, genre: "Travel", coordinate: GridPoint(column: 3, row: 1)),
            Island(id: mysteryID, genre: "Mystery", coordinate: GridPoint(column: 1, row: 3)),
        ]

        let books = [
            Book(
                id: harborLightID,
                isbn: "9780141439518",
                title: "Harbor Light",
                islandID: fictionID
            ),
            Book(
                id: saltMeridianID,
                isbn: "9780140439175",
                title: "Salt Meridian",
                islandID: historyID
            ),
            Book(
                id: quietHarborID,
                isbn: "9780140449136",
                title: "Quiet Harbor",
                islandID: poetryID,
                isFinished: true
            ),
        ]

        let session = Session(
            id: hailSessionID,
            bookID: harborLightID,
            islandID: fictionID,
            pages: 60,
            minutes: 40,
            daykey: today
        )

        let pair = IslandPair(poetryID, scienceID)
        let rhumb = Rhumb(
            pair: pair,
            weight: 2,
            bearing: RhumbGeometry.bearing(
                from: GridPoint(column: 2, row: 0),
                to: GridPoint(column: 2, row: 2)
            )
        )

        let marks: [Mark] = [
            .fix(
                FixMark(
                    id: priorFixID,
                    daykey: prior,
                    islandID: poetryID,
                    bookID: quietHarborID,
                    sessionID: makeID("cccccccc-0001-4000-8000-000000000002"),
                    pages: 24,
                    minutes: 16
                )
            ),
            .rhumb(
                RhumbMark(
                    id: priorRhumbID,
                    daykey: prior,
                    fromIsland: poetryID,
                    toIsland: scienceID,
                    cost: 40,
                    weightAfter: 2
                )
            ),
            .landfall(
                Landfall(
                    id: priorLandfallID,
                    daykey: prior,
                    islandID: poetryID,
                    bookID: quietHarborID
                )
            ),
            .fix(
                FixMark(
                    id: hailFixID,
                    daykey: today,
                    islandID: fictionID,
                    bookID: harborLightID,
                    sessionID: hailSessionID,
                    pages: 60,
                    minutes: 40
                )
            ),
        ]

        return ChartRecord(
            schemaVersion: ChartRecord.currentSchema,
            gridSize: 4,
            reachRate: ReachCost.defaultPagesPerCell,
            readingPace: 1.5,
            islands: islands,
            books: books,
            sessions: [session],
            run: Run(
                originIslandID: fictionID,
                sessionID: hailSessionID,
                remainder: 60,
                startedPages: 60
            ),
            rhumbs: [rhumb],
            marks: marks,
            phase: .hailed,
            reminder: .evening,
            onboardingComplete: true
        )
    }

    private static func priorDaykey(from today: Int) -> Int {
        let year = today / 10_000
        let month = (today / 100) % 100
        let day = today % 100
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        guard let date = calendar.date(from: components),
              let prior = calendar.date(byAdding: .day, value: -1, to: date)
        else {
            return today
        }
        return Daykey.of(prior, calendar: calendar)
    }

    private static func makeID(_ raw: String) -> UUID {
        guard let id = UUID(uuidString: raw) else {
            // Programmer error: seed identifiers are compile-time constants.
            fatalError("invalid seed UUID")
        }
        return id
    }
}
