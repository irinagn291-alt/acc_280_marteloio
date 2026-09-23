import Foundation

/// Role: Marks. A Hail seats a Fix on the book's island and writes the Run.
struct FixMark: Identifiable, Codable, Equatable, Sendable {
    var id: UUID
    var daykey: Int
    var islandID: Island.ID
    var bookID: Book.ID
    var sessionID: Session.ID
    var pages: Int
    var minutes: Int
}
