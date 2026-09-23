import Foundation

/// Role: Book. Domain title after DTO mapping. Never decoded from the wire.
struct CatalogTitle: Equatable, Codable, Sendable, Identifiable {
    var isbn: String
    var title: String
    var author: String
    var genreHint: String
    var pageCount: Int?

    var id: String { isbn.isEmpty ? title : isbn }
}

/// Role: Book. Number or numeric string. Incomplete catalog rows are normal.
struct FlexibleCount: Decodable, Equatable, Sendable {
    var intValue: Int?

    init(intValue: Int?) {
        self.intValue = intValue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            intValue = nil
            return
        }
        if let value = try? container.decode(Int.self) {
            intValue = value
            return
        }
        if let value = try? container.decode(Double.self) {
            intValue = Int(value.rounded())
            return
        }
        if let raw = try? container.decode(String.self) {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            intValue = Int(trimmed)
            return
        }
        intValue = nil
    }
}
