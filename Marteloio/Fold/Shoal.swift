import Foundation

/// Role: Fold. Fewer than two islands cannot Bear. The surface says Shoal instead of failing quiet.
enum Shoal {
    static func blocksBear(_ record: ChartRecord) -> Bool {
        record.islands.count < 2
    }
}
