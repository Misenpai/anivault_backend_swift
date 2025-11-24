import Vapor

actor JikanRateLimiter {
    private var requestTimestamps: [Date] = []
    private let maxRequestsPerSecond = 3
    private let maxRequestsPerMinute = 60

    func waitForSlot() async throws {
        while true {
            cleanup()

            let now = Date()
            let oneSecondAgo = now.addingTimeInterval(-1)
            let oneMinuteAgo = now.addingTimeInterval(-60)

            let requestsInLastSecond = requestTimestamps.filter { $0 > oneSecondAgo }.count
            let requestsInLastMinute = requestTimestamps.filter { $0 > oneMinuteAgo }.count

            if requestsInLastSecond < maxRequestsPerSecond
                && requestsInLastMinute < maxRequestsPerMinute
            {
                requestTimestamps.append(now)
                return
            }

            // Wait a bit before checking again
            try await Task.sleep(nanoseconds: 100_000_000)  // 0.1 second
        }
    }

    private func cleanup() {
        let oneMinuteAgo = Date().addingTimeInterval(-60)
        requestTimestamps = requestTimestamps.filter { $0 > oneMinuteAgo }
    }
}
