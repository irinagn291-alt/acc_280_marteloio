import Foundation

/// Role: Book. A volume moored on one island. Finished books cannot Hail.
struct Book: Identifiable, Codable, Equatable, Sendable {
    typealias ID = UUID

    var id: ID
    var isbn: String
    var title: String
    var islandID: Island.ID
    var isFinished: Bool

    init(
        id: ID = UUID(),
        isbn: String,
        title: String,
        islandID: Island.ID,
        isFinished: Bool = false
    ) {
        self.id = id
        self.isbn = isbn
        self.title = title
        self.islandID = islandID
        self.isFinished = isFinished
    }
}

/// Role: Book. Digit runs for ISBN lookup. UPC-A (12) gains a leading zero.
enum IsbnDigits {
    static func extract(from raw: String) -> [String] {
        var runs: [String] = []
        var current = ""
        for character in raw where character.isASCII {
            if character.isNumber {
                current.append(character)
            } else if !current.isEmpty {
                if (8...14).contains(current.count) {
                    runs.append(canonicalize(current) ?? current)
                }
                current = ""
            }
        }
        if !current.isEmpty, (8...14).contains(current.count) {
            runs.append(canonicalize(current) ?? current)
        }
        return runs
    }

    static func canonicalize(_ raw: String) -> String? {
        let digits = raw.filter(\.isNumber)
        if digits.count == 12 {
            return "0" + digits
        }
        if (8...14).contains(digits.count) {
            return digits
        }
        return nil
    }
}
