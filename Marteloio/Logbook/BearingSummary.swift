import Foundation

/// Role: Logbook. Thickest bearing sits above the day list as the hero row.
struct BearingSummary: Equatable, Sendable {
    var bearing: Bearing
    var weight: Int
    var pair: IslandPair
}

enum BearingSummaryQuery {
    static func thickest(in record: ChartRecord) -> BearingSummary? {
        record.rhumbs.max { left, right in
            if left.weight != right.weight {
                return left.weight < right.weight
            }
            return left.pair.low.uuidString < right.pair.low.uuidString
        }
        .map { rhumb in
            BearingSummary(bearing: rhumb.bearing, weight: rhumb.weight, pair: rhumb.pair)
        }
    }
}
