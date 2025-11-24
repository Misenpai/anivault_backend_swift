import Vapor

final class JikanService: @unchecked Sendable {
    private let client: any Client
    private let cache: any Cache
    private let baseURL = "https://api.jikan.moe/v4"
    private let rateLimiter = JikanRateLimiter()

    init(client: any Client, cache: any Cache) {
        self.client = client
        self.cache = cache
    }

    private func getCachedOrFetch<T: Content & Sendable>(_ url: String, as type: T.Type)
        async throws -> T
    {
        // Check cache first
        if let cachedData: T = try? await cache.get(url, as: T.self) {
            return cachedData
        }

        // Wait for rate limiter
        try await rateLimiter.waitForSlot()

        let uri = URI(string: url)
        let response = try await client.get(uri)

        guard response.status != .tooManyRequests else {
            // If we still get rate limited, wait and retry once
            try await Task.sleep(nanoseconds: 1_000_000_000)
            return try await getCachedOrFetch(url, as: type)
        }

        let data = try response.content.decode(T.self)

        // Cache for 24 hours
        try? await cache.set(url, to: data, expiresIn: .seconds(86400))

        return data
    }

    func getAnimeById(_ id: Int) async throws -> AnimeResponse {
        return try await getCachedOrFetch("\(baseURL)/anime/\(id)/full", as: AnimeResponse.self)
    }

    func searchAnime(query: String, page: Int, limit: Int) async throws -> SeasonAnimeResponse {
        return try await getCachedOrFetch(
            "\(baseURL)/anime?q=\(query)&page=\(page)&limit=\(limit)", as: SeasonAnimeResponse.self)
    }

    func getCurrentSeasonAnime(page: Int, limit: Int) async throws -> SeasonAnimeResponse {
        return try await getCachedOrFetch(
            "\(baseURL)/seasons/now?page=\(page)&limit=\(limit)", as: SeasonAnimeResponse.self)
    }

    func getUpcomingSeasonAnime(page: Int, limit: Int) async throws -> SeasonAnimeResponse {
        return try await getCachedOrFetch(
            "\(baseURL)/seasons/upcoming?page=\(page)&limit=\(limit)", as: SeasonAnimeResponse.self)
    }

    func getSeasonAnime(year: Int, season: String, page: Int) async throws -> SeasonAnimeResponse {
        return try await getCachedOrFetch(
            "\(baseURL)/seasons/\(year)/\(season)?page=\(page)", as: SeasonAnimeResponse.self)
    }

    func getTopAnime(page: Int, limit: Int) async throws -> SeasonAnimeResponse {
        return try await getCachedOrFetch(
            "\(baseURL)/top/anime?page=\(page)&limit=\(limit)", as: SeasonAnimeResponse.self)
    }
}
