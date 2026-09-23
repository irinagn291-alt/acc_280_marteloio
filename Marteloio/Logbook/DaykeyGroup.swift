import Foundation

/// Role: Logbook. Marks for one daykey, ready for the sheet list.
struct DaykeyGroup: Equatable, Sendable {
    var daykey: Int
    var fixes: [FixMark]
    var rhumbs: [RhumbMark]
    var luffs: [LuffMark]
    var landfalls: [Landfall]
}

enum LogbookQuery {
    static func groups(from record: ChartRecord) -> [DaykeyGroup] {
        let keys = Set(record.marks.map(\.daykey)).sorted(by: >)
        return keys.map { key in
            var fixes: [FixMark] = []
            var rhumbs: [RhumbMark] = []
            var luffs: [LuffMark] = []
            var landfalls: [Landfall] = []
            for mark in record.marks where mark.daykey == key {
                switch mark {
                case .fix(let item): fixes.append(item)
                case .rhumb(let item): rhumbs.append(item)
                case .luff(let item): luffs.append(item)
                case .landfall(let item): landfalls.append(item)
                }
            }
            return DaykeyGroup(
                daykey: key,
                fixes: fixes,
                rhumbs: rhumbs,
                luffs: luffs,
                landfalls: landfalls
            )
        }
    }

    static func pagesPerIsland(from record: ChartRecord, daykey: Int? = nil) -> [Island.ID: Int] {
        var totals: [Island.ID: Int] = [:]
        for mark in record.marks {
            guard case .fix(let fix) = mark else { continue }
            if let daykey, fix.daykey != daykey { continue }
            totals[fix.islandID, default: 0] += fix.pages
        }
        return totals
    }

    static func rhumbCountPerPair(from record: ChartRecord) -> [IslandPair: Int] {
        var counts: [IslandPair: Int] = [:]
        for rhumb in record.rhumbs {
            counts[rhumb.pair] = rhumb.weight
        }
        return counts
    }
}
