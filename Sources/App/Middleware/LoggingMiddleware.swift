import Vapor

struct LoggingMiddleware: AsyncMiddleware, Sendable {

    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response
    {
        let startTime = Date()

        logRequest(request, startTime: startTime)

        do {
            let response = try await next.respond(to: request)

            logResponse(response, for: request, startTime: startTime)

            return response
        } catch {

            logError(error, for: request, startTime: startTime)
            throw error
        }
    }

    private func logRequest(_ request: Request, startTime: Date) {
        let method = request.method.rawValue
        let path = request.url.path
        let clientIP = request.clientIP ?? "unknown"
        let userAgent = request.userAgent ?? "unknown"
        let requestID = request.requestID

        request.logger.info(
            """
            ▶️ \(method) \(path)
               Request ID: \(requestID)
               Client IP: \(clientIP)
               User-Agent: \(userAgent)
            """)
    }

    private func logResponse(_ response: Response, for request: Request, startTime: Date) {
        let duration = Date().timeIntervalSince(startTime)
        let method = request.method.rawValue
        let path = request.url.path
        let status = response.status.code
        let requestID = request.requestID

        let emoji = getStatusEmoji(status)

        request.logger.info(
            """
            \(emoji) \(method) \(path) - \(status)
               Request ID: \(requestID)
               Duration: \(String(format: "%.3f", duration))s
            """)
    }

    private func logError(_ error: any Error, for request: Request, startTime: Date) {
        let duration = Date().timeIntervalSince(startTime)
        let method = request.method.rawValue
        let path = request.url.path
        let requestID = request.requestID

        if let abort = error as? Abort {
            request.logger.warning(
                """
                ⚠️ \(method) \(path) - \(abort.status.code)
                   Request ID: \(requestID)
                   Duration: \(String(format: "%.3f", duration))s
                   Reason: \(abort.reason)
                """)
        } else {
            request.logger.error(
                """
                ❌ \(method) \(path) - 500
                   Request ID: \(requestID)
                   Duration: \(String(format: "%.3f", duration))s
                   Error: \(error)
                """)
        }
    }

    private func getStatusEmoji(_ status: UInt) -> String {
        switch status {
        case 200..<300:
            return "✅"
        case 300..<400:
            return "↪️"
        case 400..<500:
            return "⚠️"
        case 500..<600:
            return "❌"
        default:
            return "❓"
        }
    }
}

struct RequestDurationMiddleware: AsyncMiddleware, Sendable {

    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response
    {
        let startTime = Date()

        let response = try await next.respond(to: request)

        let duration = Date().timeIntervalSince(startTime)
        response.headers.add(name: "X-Response-Time", value: "\(Int(duration * 1000))ms")

        return response
    }
}

actor RateLimitStore {
    private var requests: [String: [Date]] = [:]

    func addRequest(for identifier: String, at date: Date) {
        requests[identifier, default: []].append(date)
    }

    func getRequests(for identifier: String, since date: Date) -> Int {
        guard let userRequests = requests[identifier] else { return 0 }

        let recentRequests = userRequests.filter { $0 > date }
        requests[identifier] = recentRequests

        return recentRequests.count
    }

    func cleanup() {
        let cutoff = Date().addingTimeInterval(-3600)
        for (key, dates) in requests {
            requests[key] = dates.filter { $0 > cutoff }
            if requests[key]?.isEmpty ?? true {
                requests.removeValue(forKey: key)
            }
        }
    }
}

struct RateLimitMiddleware: AsyncMiddleware, Sendable {
    private let maxRequests: Int
    private let timeWindow: TimeInterval
    private let store: RateLimitStore

    init(
        maxRequests: Int = Constants.API.RateLimit.maxRequests,
        timeWindow: TimeInterval = Constants.API.RateLimit.timeWindow,
        store: RateLimitStore = RateLimitStore()
    ) {
        self.maxRequests = maxRequests
        self.timeWindow = timeWindow
        self.store = store
    }

    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response
    {

        if let user = request.auth.get(User.self), user.roleId == Constants.Role.admin.rawValue {
            return try await next.respond(to: request)
        }

        let identifier = request.clientIP ?? "unknown"
        let now = Date()
        let windowStart = now.addingTimeInterval(-timeWindow)

        let currentRequests = await store.getRequests(for: identifier, since: windowStart)

        if currentRequests >= maxRequests {
            let resetTime = now.addingTimeInterval(timeWindow)

            let response = Response(status: .tooManyRequests)
            response.headers.add(name: "X-RateLimit-Limit", value: "\(maxRequests)")
            response.headers.add(name: "X-RateLimit-Remaining", value: "0")
            response.headers.add(name: "X-RateLimit-Reset", value: "\(Int(resetTime.timestamp))")
            response.headers.add(name: "Retry-After", value: "\(Int(timeWindow))")

            try response.content.encode(
                ErrorResponse(
                    code: "RATE_LIMIT_EXCEEDED",
                    message: "Too many requests. Please try again later.",
                    details: "Rate limit: \(maxRequests) requests per \(Int(timeWindow)) seconds"
                )
            )

            return response
        }

        await store.addRequest(for: identifier, at: now)

        let response = try await next.respond(to: request)

        let remaining = maxRequests - currentRequests - 1
        response.headers.add(name: "X-RateLimit-Limit", value: "\(maxRequests)")
        response.headers.add(name: "X-RateLimit-Remaining", value: "\(max(0, remaining))")
        response.headers.add(
            name: "X-RateLimit-Reset",
            value: "\(Int(now.addingTimeInterval(timeWindow).timestamp))"
        )

        return response
    }
}

struct RateLimitStoreKey: StorageKey {
    typealias Value = RateLimitStore
}

extension Application {
    var rateLimitStore: RateLimitStore {
        get {
            if let existing = storage[RateLimitStoreKey.self] {
                return existing
            }
            let new = RateLimitStore()
            storage[RateLimitStoreKey.self] = new
            return new
        }
        set {
            storage[RateLimitStoreKey.self] = newValue
        }
    }
}
