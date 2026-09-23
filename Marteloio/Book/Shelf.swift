import Foundation

/// Role: Book. The moored collection. Hail samples a book that is not Finished.
struct Shelf: Equatable, Sendable {
    var books: [Book]

    func moored(on islandID: Island.ID) -> [Book] {
        books.filter { $0.islandID == islandID && !$0.isFinished }
    }

    func hailable() -> [Book] {
        books.filter { !$0.isFinished }
    }

    func book(_ id: Book.ID) -> Book? {
        books.first { $0.id == id }
    }

    func first(isbn: String) -> Book? {
        let key = IsbnDigits.canonicalize(isbn) ?? isbn
        return books.first { (IsbnDigits.canonicalize($0.isbn) ?? $0.isbn) == key }
    }
}
