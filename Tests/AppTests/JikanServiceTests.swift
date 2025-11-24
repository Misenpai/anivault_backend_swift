import XCTVapor

@testable import App

final class JikanServiceTests: XCTestCase {

    func testRateLimiting() async throws {
        let mockClient = MockClient()
        let mockCache = MockCache()
        let service = JikanService(client: mockClient, cache: mockCache)

        let start = Date()

        // Make 5 requests. Rate limit is 3/sec.
        async let r1 = service.getAnimeById(1)
        async let r2 = service.getAnimeById(2)
        async let r3 = service.getAnimeById(3)
        async let r4 = service.getAnimeById(4)
        async let r5 = service.getAnimeById(5)

        _ = try await [r1, r2, r3, r4, r5]

        let duration = Date().timeIntervalSince(start)

        // It should take at least 1 second to process 5 requests with 3/sec limit
        XCTAssertTrue(duration >= 1.0, "Requests should be rate limited. Duration: \(duration)")
    }

    func testCaching() async throws {
        let mockClient = MockClient()
        let mockCache = MockCache()
        let service = JikanService(client: mockClient, cache: mockCache)

        // First request
        _ = try await service.getAnimeById(1)
        XCTAssertEqual(mockClient.requestCount, 1)

        // Second request (should be cached)
        _ = try await service.getAnimeById(1)
        XCTAssertEqual(mockClient.requestCount, 1)
    }
}

final class MockClient: Client, @unchecked Sendable {
    var eventLoop: any EventLoop { EmbeddedEventLoop() }
    private var _requestCount = 0
    private let lock = NSLock()

    var requestCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return _requestCount
    }

    func send(_ request: ClientRequest) -> EventLoopFuture<ClientResponse> {
        lock.lock()
        _requestCount += 1
        lock.unlock()

        let response = ClientResponse(
            status: .ok, headers: ["content-type": "application/json"],
            body: ByteBuffer(
                string:
                    "{\"data\": {\"mal_id\": 1, \"title\": \"Test Anime\", \"images\": {\"jpg\": {\"image_url\": \"\"}, \"webp\": {\"image_url\": \"\"}}, \"status\": \"Finished Airing\", \"airing\": false}}"
            ))
        return eventLoop.makeSucceededFuture(response)
    }

    func delegating(to eventLoop: any EventLoop) -> any Client {
        self
    }
}

struct Box<T>: @unchecked Sendable {
    let value: T
}

final class MockCache: Cache, @unchecked Sendable {
    private var storage: [String: Any] = [:]
    private let lock = NSLock()

    func get<T>(_ key: String, as type: T.Type) -> EventLoopFuture<T?> where T: Decodable {
        let eventLoop = EmbeddedEventLoop()
        let promise = eventLoop.makePromise(of: Box<T>?.self)

        lock.lock()
        let value = storage[key] as? T
        lock.unlock()

        if let value = value {
            promise.succeed(Box(value: value))
        } else {
            promise.succeed(nil)
        }
        return promise.futureResult.map { $0?.value }
    }

    func set<T>(_ key: String, to value: T?) -> EventLoopFuture<Void> where T: Encodable {
        return self.set(key, to: value, expiresIn: nil)
    }

    func set<T>(_ key: String, to value: T?, expiresIn: CacheExpirationTime?) -> EventLoopFuture<
        Void
    > where T: Encodable {
        let eventLoop = EmbeddedEventLoop()
        let promise = eventLoop.makePromise(of: Void.self)

        lock.lock()
        if let value = value {
            storage[key] = value
        } else {
            storage.removeValue(forKey: key)
        }
        lock.unlock()

        promise.succeed(())
        return promise.futureResult
    }

    func `for`(_ request: Request) -> MockCache {
        self
    }
}
