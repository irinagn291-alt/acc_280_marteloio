import Foundation

/// Role: App. Genre islands for a device chart that has not been seeded.
enum StarterChart {
    static func islands() -> [Island] {
        [
            Island(id: DemoSeed.fictionID, genre: "Fiction", coordinate: GridPoint(column: 0, row: 0)),
            Island(id: DemoSeed.historyID, genre: "History", coordinate: GridPoint(column: 0, row: 2)),
            Island(id: DemoSeed.poetryID, genre: "Poetry", coordinate: GridPoint(column: 2, row: 0)),
            Island(id: DemoSeed.scienceID, genre: "Science", coordinate: GridPoint(column: 2, row: 2)),
            Island(id: DemoSeed.travelID, genre: "Travel", coordinate: GridPoint(column: 3, row: 1)),
            Island(id: DemoSeed.mysteryID, genre: "Mystery", coordinate: GridPoint(column: 1, row: 3)),
        ]
    }
}
