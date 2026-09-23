import Foundation

/// Role: Design. Locale numbers for Runs, costs and page totals. Round only here.
enum ChartNumbers {
    static func pages(_ value: Int) -> String {
        integer.string(from: NSNumber(value: value)) ?? String(value)
    }

    static func daykey(_ value: Int) -> String {
        let year = value / 10_000
        let month = (value / 100) % 100
        let day = value % 100
        var parts = DateComponents()
        parts.year = year
        parts.month = month
        parts.day = day
        guard let date = Calendar.current.date(from: parts) else {
            return integer.string(from: NSNumber(value: value)) ?? String(value)
        }
        return dayFormatter.string(from: date)
    }

    private static let integer: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()
}
