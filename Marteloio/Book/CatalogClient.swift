import Foundation

/// Role: Book. Typed hop errors. A 404 is not retried.
enum CatalogError: Error, Equatable, Sendable {
    case timeout
    case transport
    case httpStatus(Int)
    case notFound
    case decode
    case cancelled
}

protocol CatalogTransport: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

struct URLSessionCatalogTransport: CatalogTransport {
    let session: URLSession

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}

/// Role: Book. One client owns title search and ISBN resolve. DTO in, CatalogTitle out.
actor CatalogClient {
    static let userAgent = "Marteloio/1.0 (iOS; +https://marteloio-chart.pro)"
    static let timeout: TimeInterval = 15

    private let transport: any CatalogTransport
    private var memory: [String: CatalogTitle] = [:]
    private var searchTask: Task<[CatalogTitle], Error>?
    private var lookupTask: Task<CatalogTitle, Error>?

    init(transport: any CatalogTransport, primed: [CatalogTitle] = []) {
        self.transport = transport
        for title in primed {
            memory[title.isbn] = title
        }
    }

    init(session: URLSession? = nil, primed: [CatalogTitle] = []) {
        if let session {
            self.transport = URLSessionCatalogTransport(session: session)
        } else {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.timeoutIntervalForRequest = Self.timeout
            configuration.timeoutIntervalForResource = Self.timeout
            configuration.httpAdditionalHeaders = ["User-Agent": Self.userAgent]
            self.transport = URLSessionCatalogTransport(session: URLSession(configuration: configuration))
        }
        for title in primed {
            memory[title.isbn] = title
        }
    }

    func cached(_ isbn: String) -> CatalogTitle? {
        let key = IsbnDigits.canonicalize(isbn) ?? isbn
        return memory[key]
    }

    func remember(_ title: CatalogTitle) {
        let key = IsbnDigits.canonicalize(title.isbn) ?? title.isbn
        guard !key.isEmpty else { return }
        var stored = title
        stored.isbn = key
        memory[key] = stored
    }

    func cachedTitles() -> [CatalogTitle] {
        Array(memory.values)
    }

    func search(title query: String) async throws -> [CatalogTitle] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return [] }
        searchTask?.cancel()
        let task = Task { try await self.performSearch(needle) }
        searchTask = task
        do {
            return try await task.value
        } catch is CancellationError {
            throw CatalogError.cancelled
        }
    }

    /// Debounce typed search by 300 ms and cancel the previous hop.
    func searchDebounced(title query: String) async throws -> [CatalogTitle] {
        try await Task.sleep(nanoseconds: 300_000_000)
        try Task.checkCancellation()
        return try await search(title: query)
    }

    func lookup(isbn raw: String) async throws -> CatalogTitle {
        guard let isbn = IsbnDigits.canonicalize(raw) ?? (raw.isEmpty ? nil : raw) else {
            throw CatalogError.notFound
        }
        if let hit = memory[isbn] { return hit }
        lookupTask?.cancel()
        let task = Task { try await self.performLookup(isbn) }
        lookupTask = task
        do {
            let title = try await task.value
            remember(title)
            return title
        } catch is CancellationError {
            throw CatalogError.cancelled
        }
    }

    private func performSearch(_ query: String) async throws -> [CatalogTitle] {
        try Task.checkCancellation()
        do {
            let data = try await fetch(request(for: Self.searchURL(query: query)))
            let titles = try Self.mapSearch(data)
            for title in titles { remember(title) }
            if titles.isEmpty {
                return LocalShelf.search(query: query)
            }
            return titles
        } catch let error as CatalogError where error == .cancelled {
            throw error
        } catch {
            let local = LocalShelf.search(query: query)
            if !local.isEmpty { return local }
            throw error
        }
    }

    private func performLookup(_ isbn: String) async throws -> CatalogTitle {
        try Task.checkCancellation()
        let books = try await fetch(request(for: Self.booksURL(isbn: isbn)))
        if let title = try Self.mapBooks(books, isbn: isbn) {
            return title
        }
        let leaf = try await fetch(request(for: Self.isbnURL(isbn: isbn)))
        if let title = try Self.mapISBN(leaf, isbn: isbn) {
            return title
        }
        throw CatalogError.notFound
    }

    private func request(for url: URL) -> URLRequest {
        var request = URLRequest(url: url, timeoutInterval: Self.timeout)
        request.httpMethod = "GET"
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        return request
    }

    private func fetch(_ request: URLRequest) async throws -> Data {
        do {
            return try await send(request)
        } catch let error as CatalogError {
            throw error
        } catch is CancellationError {
            throw CatalogError.cancelled
        } catch {
            if Self.cancelled(error) { throw CatalogError.cancelled }
            guard Self.transient(error) else { throw mappedTransport(error) }
            do {
                return try await send(request)
            } catch let error as CatalogError {
                throw error
            } catch is CancellationError {
                throw CatalogError.cancelled
            } catch {
                if Self.cancelled(error) { throw CatalogError.cancelled }
                throw mappedTransport(error)
            }
        }
    }

    private func send(_ request: URLRequest) async throws -> Data {
        try Task.checkCancellation()
        let (data, response) = try await transport.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw CatalogError.transport
        }
        if http.statusCode == 404 {
            throw CatalogError.notFound
        }
        guard (200..<300).contains(http.statusCode) else {
            throw CatalogError.httpStatus(http.statusCode)
        }
        return data
    }

    private func mappedTransport(_ error: Error) -> CatalogError {
        if (error as? URLError)?.code == .timedOut {
            return .timeout
        }
        return .transport
    }

    static func searchURL(query: String) -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "openlibrary.org"
        components.path = "/search.json"
        components.queryItems = [
            URLQueryItem(name: "title", value: query),
            URLQueryItem(name: "limit", value: "12"),
        ]
        // Programmer constant. Host and path are fixed in this type.
        return components.url!
    }

    static func booksURL(isbn: String) -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "openlibrary.org"
        components.path = "/api/books"
        components.queryItems = [
            URLQueryItem(name: "bibkeys", value: "ISBN:\(isbn)"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "jscmd", value: "data"),
        ]
        // Programmer constant. Host and path are fixed in this type.
        return components.url!
    }

    static func isbnURL(isbn: String) -> URL {
        // Programmer constant. Path uses digits only.
        URL(string: "https://openlibrary.org/isbn/\(isbn).json")!
    }

    static func mapSearch(_ data: Data) throws -> [CatalogTitle] {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        let dto: OpenLibrarySearchDTO
        do {
            dto = try decoder.decode(OpenLibrarySearchDTO.self, from: data)
        } catch {
            throw CatalogError.decode
        }
        return (dto.docs ?? []).compactMap(\.asTitle)
    }

    static func mapBooks(_ data: Data, isbn: String) throws -> CatalogTitle? {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        let table: [String: OpenLibraryBookDTO]
        do {
            table = try decoder.decode([String: OpenLibraryBookDTO].self, from: data)
        } catch {
            throw CatalogError.decode
        }
        guard let dto = table["ISBN:\(isbn)"] ?? table.values.first else {
            return nil
        }
        return dto.asTitle(isbn: isbn)
    }

    static func mapISBN(_ data: Data, isbn: String) throws -> CatalogTitle? {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        do {
            let dto = try decoder.decode(OpenLibraryISBNDTO.self, from: data)
            return dto.asTitle(isbn: isbn)
        } catch {
            throw CatalogError.decode
        }
    }

    private static func transient(_ error: Error) -> Bool {
        guard let urlError = error as? URLError else { return false }
        switch urlError.code {
        case .timedOut, .networkConnectionLost, .notConnectedToInternet,
             .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed:
            return true
        default:
            return false
        }
    }

    private static func cancelled(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        if let urlError = error as? URLError, urlError.code == .cancelled { return true }
        return false
    }
}

/// Role: Book. Wire shape for /search.json. Keys stay as the service sent them.
struct OpenLibrarySearchDTO: Decodable, Equatable, Sendable {
    var docs: [OpenLibrarySearchDocDTO]?
}

struct OpenLibrarySearchDocDTO: Decodable, Equatable, Sendable {
    var title: String?
    var author_name: [String]?
    var isbn: [String]?
    var subject: [String]?
    var number_of_pages_median: FlexibleCount?

    var asTitle: CatalogTitle? {
        let name = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !name.isEmpty else { return nil }
        let code = isbn?.compactMap(IsbnDigits.canonicalize).first ?? isbn?.first ?? ""
        let author = author_name?
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty } ?? ""
        let genre = subject?
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty } ?? ""
        return CatalogTitle(
            isbn: code,
            title: name,
            author: author,
            genreHint: genre,
            pageCount: number_of_pages_median?.intValue
        )
    }
}

/// Role: Book. Wire shape for /api/books.
struct OpenLibraryBookDTO: Decodable, Equatable, Sendable {
    var title: String?
    var authors: [OpenLibraryNamedDTO]?
    var subjects: [OpenLibraryNamedDTO]?
    var number_of_pages: FlexibleCount?

    func asTitle(isbn: String) -> CatalogTitle? {
        let name = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !name.isEmpty else { return nil }
        let author = authors?.compactMap { $0.name?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty } ?? ""
        let genre = subjects?.compactMap { $0.name?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty } ?? ""
        return CatalogTitle(
            isbn: isbn,
            title: name,
            author: author,
            genreHint: genre,
            pageCount: number_of_pages?.intValue
        )
    }
}

/// Role: Book. Wire shape for /isbn/{code}.json.
struct OpenLibraryISBNDTO: Decodable, Equatable, Sendable {
    var title: String?
    var subjects: [String]?
    var number_of_pages: FlexibleCount?
    var by_statement: String?

    func asTitle(isbn: String) -> CatalogTitle? {
        let name = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !name.isEmpty else { return nil }
        let author = by_statement?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let genre = subjects?
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty } ?? ""
        return CatalogTitle(
            isbn: isbn,
            title: name,
            author: author,
            genreHint: genre,
            pageCount: number_of_pages?.intValue
        )
    }
}

struct OpenLibraryNamedDTO: Decodable, Equatable, Sendable {
    var name: String?
}
