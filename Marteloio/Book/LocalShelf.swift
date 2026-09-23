import Foundation

/// Role: Book. Offline fallback when title search is empty or the hop fails.
enum LocalShelf {
    static func items(from bundle: Bundle = .main) -> [CatalogTitle] {
        if let url = bundle.url(forResource: "LocalShelf", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let rows = try? ChartCodec.decoder().decode([LocalShelfDTO].self, from: data) {
            let mapped = rows.compactMap(\.asTitle)
            if !mapped.isEmpty { return mapped }
        }
        return embedded
    }

    static func search(query: String, in titles: [CatalogTitle]? = nil) -> [CatalogTitle] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return [] }
        let haystack = titles ?? items()
        return haystack.filter { title in
            title.title.lowercased().contains(needle)
                || title.author.lowercased().contains(needle)
                || title.genreHint.lowercased().contains(needle)
        }
    }

    private static let embedded: [CatalogTitle] = [
        CatalogTitle(
            isbn: "9780141439518",
            title: "Harbor Light",
            author: "North Binding",
            genreHint: "Fiction",
            pageCount: 312
        ),
        CatalogTitle(
            isbn: "9780140439175",
            title: "Salt Meridian",
            author: "Clara Fen",
            genreHint: "History",
            pageCount: 288
        ),
        CatalogTitle(
            isbn: "9780140449136",
            title: "Quiet Harbor",
            author: "Ivy Quill",
            genreHint: "Poetry",
            pageCount: 96
        ),
        CatalogTitle(
            isbn: "9780140449266",
            title: "Paper Windrose",
            author: "Tomas Gale",
            genreHint: "Science",
            pageCount: 240
        ),
        CatalogTitle(
            isbn: "9780141187761",
            title: "Leeward Pages",
            author: "Mara Holt",
            genreHint: "Travel",
            pageCount: 176
        ),
    ]
}

/// Role: Book. Wire shape for LocalShelf.json. Keys stay as written.
struct LocalShelfDTO: Decodable, Equatable, Sendable {
    var isbn: String?
    var title: String?
    var author: String?
    var genre: String?
    var pageCount: FlexibleCount?

    var asTitle: CatalogTitle? {
        let name = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !name.isEmpty else { return nil }
        return CatalogTitle(
            isbn: IsbnDigits.canonicalize(isbn ?? "") ?? (isbn ?? ""),
            title: name,
            author: author?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            genreHint: genre?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            pageCount: pageCount?.intValue
        )
    }
}
