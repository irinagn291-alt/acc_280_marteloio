import Foundation

/// Role: App. Launch keys, not tabs. Parsed once after onboarding.
enum ReviewScreenKey: String, Equatable, Sendable {
    case today
    case log
    case goals
    case shelf
}

enum ReviewScreenKeys {
    static let argument = "-ReviewScreen"

    static func parse(_ arguments: [String]) -> ReviewScreenKey? {
        guard let index = arguments.firstIndex(of: argument),
              arguments.indices.contains(index + 1)
        else {
            return nil
        }
        return ReviewScreenKey(rawValue: arguments[index + 1])
    }

    static func parse(from processInfo: ProcessInfo) -> ReviewScreenKey? {
        parse(processInfo.arguments)
    }
}
