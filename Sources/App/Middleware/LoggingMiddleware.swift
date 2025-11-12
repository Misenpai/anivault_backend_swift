import Vapor

struct LoggingMiddleware: AsyncMiddleware {

    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
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
        let method = request.method.string
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
        let method = request.method.string
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

    private func logError(_ error: Error, for request: Request, startTime: Date) {
        let duration = Date().timeIntervalSince(startTime)
        let method = request.method.string
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

struct RequestDurationMiddleware: AsyncMiddleware {

    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        let startTime = Date()

        let response = try await next.respond(to: request)

        let duration = Date().timeIntervalSince(startTime)
        response.headers.add(name: "X-Response-Time", value: "\(Int(duration * 1000))ms")

        return response
    }
}

struct RateLimitMiddleware: AsyncMiddleware {

    struct RateLimitStorage {
        var requests: [String: [Date]] = [:]
    }

    private let maxRequests: Int
    private let timeWindow: TimeInterval

    init(
        maxRequests: Int = Constants.API.RateLimit.maxRequests,
        timeWindow: TimeInterval = Constants.API.RateLimit.timeWindow
    ) {
        self.maxRequests = maxRequests
        self.timeWindow = timeWindow
    }

    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {

        if let user = request.auth.get(User.self), user.roleId == Constants.Role.admin.rawValue {
            return try await next.respond(to: request)
        }

        let identifier = request.clientIP ?? "unknown"
        let now = Date()

        let response = try await next.respond(to: request)

        response.headers.add(name: "X-RateLimit-Limit", value: "\(maxRequests)")
        response.headers.add(name: "X-RateLimit-Remaining", value: "\(maxRequests)")
        response.headers.add(
            name: "X-RateLimit-Reset", value: "\(Int(now.addingTimeInterval(timeWindow).timestamp))"
        )

        return response
    }
}
