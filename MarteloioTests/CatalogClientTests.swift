import XCTest
@testable import Marteloio

private actor ScriptedTransport: CatalogTransport {
    private var results: [Result<(Data, URLResponse), Error>]
    private var requests: [URLRequest] = []

    init(results: [Result<(Data, URLResponse), Error>]) {
        self.results = results
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        guard !results.isEmpty else { throw URLError(.cannotConnectToHost) }
        return try results.removeFirst().get()
    }

    func recordedRequests() -> [URLRequest] {
        requests
    }
}

final class CatalogClientTests: XCTestCase {
    func test_setsUserAgentOnEveryRequest() async throws {
        let body = Data("""
        {"ISBN:9780141439518":{"title":"Harbor Light","authors":[{"name":"North Binding"}],"number_of_pages":312}}
        """.utf8)
        let transport = ScriptedTransport(results: [.success((body, http(200)))])
        let client = CatalogClient(transport: transport)
        let title = try await client.lookup(isbn: "9780141439518")
        XCTAssertEqual(title.title, "Harbor Light")
        XCTAssertEqual(title.author, "North Binding")
        XCTAssertEqual(title.pageCount, 312)
        let request = await transport.recordedRequests().first
        XCTAssertEqual(request?.value(forHTTPHeaderField: "User-Agent"), CatalogClient.userAgent)
        XCTAssertEqual(request?.timeoutInterval, 15)
        XCTAssertEqual(CatalogClient.userAgent, "Marteloio/1.0 (iOS; +https://marteloio-chart.pro)")
    }

    func test_acceptsNumericStringPages() async throws {
        let body = Data("""
        {"ISBN:9780141439518":{"title":"Harbor Light","number_of_pages":"96"}}
        """.utf8)
        let transport = ScriptedTransport(results: [.success((body, http(200)))])
        let client = CatalogClient(transport: transport)
        let title = try await client.lookup(isbn: "9780141439518")
        XCTAssertEqual(title.pageCount, 96)
    }

    func test_retriesTransientTransportOnce() async throws {
        let body = Data("""
        {"ISBN:9780141439518":{"title":"Harbor Light","number_of_pages":4}}
        """.utf8)
        let transport = ScriptedTransport(results: [
            .failure(URLError(.timedOut)),
            .success((body, http(200))),
        ])
        let client = CatalogClient(transport: transport)
        let title = try await client.lookup(isbn: "9780141439518")
        XCTAssertEqual(title.title, "Harbor Light")
        let count = await transport.recordedRequests().count
        XCTAssertEqual(count, 2)
    }

    func test_doesNotRetry404() async {
        let transport = ScriptedTransport(results: [
            .success((Data(), http(404))),
            .success((Data("{\"ISBN:9780141439518\":{\"title\":\"No\"}}".utf8), http(200))),
        ])
        let client = CatalogClient(transport: transport)
        do {
            _ = try await client.lookup(isbn: "9780141439518")
            XCTFail("expected notFound")
        } catch {
            XCTAssertEqual(error as? CatalogError, .notFound)
        }
        let count = await transport.recordedRequests().count
        XCTAssertEqual(count, 1)
    }

    func test_emptyBooksObjectFallsThroughToISBNEndpoint() async throws {
        let leaf = Data("""
        {"title":"Leaf Title","subjects":["Fiction"],"number_of_pages":128}
        """.utf8)
        let transport = ScriptedTransport(results: [
            .success((Data("{}".utf8), http(200))),
            .success((leaf, http(200))),
        ])
        let client = CatalogClient(transport: transport)
        let title = try await client.lookup(isbn: "9780141439518")
        XCTAssertEqual(title.title, "Leaf Title")
        XCTAssertEqual(title.genreHint, "Fiction")
        let count = await transport.recordedRequests().count
        XCTAssertEqual(count, 2)
        let urls = await transport.recordedRequests().compactMap(\.url)
        XCTAssertTrue(urls[0].path.contains("/api/books"))
        XCTAssertTrue(urls[1].path.contains("/isbn/"))
    }

    func test_malformedJSONIsDecodingError() async {
        let transport = ScriptedTransport(results: [
            .success((Data("{".utf8), http(200))),
        ])
        let client = CatalogClient(transport: transport)
        do {
            _ = try await client.lookup(isbn: "9780141439518")
            XCTFail("expected decode")
        } catch {
            XCTAssertEqual(error as? CatalogError, .decode)
        }
    }

    func test_usesMemoryCacheOnSecondLookup() async throws {
        let body = Data("""
        {"ISBN:9780141439518":{"title":"Harbor Light"}}
        """.utf8)
        let transport = ScriptedTransport(results: [.success((body, http(200)))])
        let client = CatalogClient(transport: transport)
        _ = try await client.lookup(isbn: "9780141439518")
        _ = try await client.lookup(isbn: "9780141439518")
        let count = await transport.recordedRequests().count
        XCTAssertEqual(count, 1)
    }

    func test_titleSearchMapsDocsAndFallsBackToLocalShelf() async throws {
        let body = Data("""
        {"docs":[{"title":"Paper Windrose","author_name":["Tomas Gale"],"isbn":["9780140449266"],"subject":["Science"],"number_of_pages_median":240}]}
        """.utf8)
        let transport = ScriptedTransport(results: [.success((body, http(200)))])
        let client = CatalogClient(transport: transport)
        let titles = try await client.search(title: "Windrose")
        XCTAssertEqual(titles.first?.title, "Paper Windrose")
        XCTAssertEqual(titles.first?.pageCount, 240)

        let failing = ScriptedTransport(results: [.failure(URLError(.notConnectedToInternet))])
        let offline = CatalogClient(transport: failing)
        let local = try await offline.search(title: "Harbor Light")
        XCTAssertEqual(local.first?.title, "Harbor Light")
    }

    func test_emptySearchDoesNotHitTheNetwork() async throws {
        let transport = ScriptedTransport(results: [.success((Data("{}".utf8), http(200)))])
        let client = CatalogClient(transport: transport)
        let titles = try await client.search(title: "   ")
        XCTAssertTrue(titles.isEmpty)
        let count = await transport.recordedRequests().count
        XCTAssertEqual(count, 0)
    }

    func test_isbnCanonicalizesTwelveDigitUPCA() {
        XCTAssertEqual(IsbnDigits.canonicalize("012345678905"), "0012345678905")
        XCTAssertEqual(IsbnDigits.extract(from: "see 9780141439518 now").first, "9780141439518")
    }

    private func http(_ status: Int) -> HTTPURLResponse {
        HTTPURLResponse(
            url: URL(string: "https://openlibrary.org/isbn/9780141439518.json")!,
            statusCode: status,
            httpVersion: nil,
            headerFields: nil
        )!
    }
}
