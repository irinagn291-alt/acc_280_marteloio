import Foundation

/// Role: Session. One Hail: pages become the Run, minutes stay on the Fix.
struct Session: Identifiable, Codable, Equatable, Sendable {
    typealias ID = UUID

    var id: ID
    var bookID: Book.ID
    var islandID: Island.ID
    var pages: Int
    var minutes: Int
    var daykey: Int

    init(
        id: ID = UUID(),
        bookID: Book.ID,
        islandID: Island.ID,
        pages: Int,
        minutes: Int,
        daykey: Int
    ) {
        self.id = id
        self.bookID = bookID
        self.islandID = islandID
        self.pages = pages
        self.minutes = minutes
        self.daykey = daykey
    }
}
