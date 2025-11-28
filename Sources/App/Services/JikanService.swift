import Vapor

struct JikanService: @unchecked Sendable {
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

    func getAnimeFullById(_ id: Int) async throws -> AnimeResponse {
        return try await getCachedOrFetch("\(baseURL)/anime/\(id)/full", as: AnimeResponse.self)
    }

    func getAnimeCharacters(_ id: Int) async throws -> JikanListResponse<CharacterDTO> {
        return try await getCachedOrFetch(
            "\(baseURL)/anime/\(id)/characters", as: JikanListResponse<CharacterDTO>.self)
    }

    func getAnimeStaff(_ id: Int) async throws -> JikanListResponse<StaffDTO> {
        return try await getCachedOrFetch(
            "\(baseURL)/anime/\(id)/staff", as: JikanListResponse<StaffDTO>.self)
    }

    func getAnimeEpisodes(_ id: Int, page: Int) async throws -> JikanListResponse<EpisodeDTO> {
        return try await getCachedOrFetch(
            "\(baseURL)/anime/\(id)/episodes?page=\(page)", as: JikanListResponse<EpisodeDTO>.self)
    }

    func getAnimeEpisodeById(_ id: Int, episode: Int) async throws -> JikanDataResponse<EpisodeDTO>
    {
        return try await getCachedOrFetch(
            "\(baseURL)/anime/\(id)/episodes/\(episode)", as: JikanDataResponse<EpisodeDTO>.self)
    }

    func getAnimeNews(_ id: Int, page: Int) async throws -> JikanListResponse<NewsDTO> {
        return try await getCachedOrFetch(
            "\(baseURL)/anime/\(id)/news?page=\(page)", as: JikanListResponse<NewsDTO>.self)
    }

    func getAnimeForum(_ id: Int, filter: String) async throws -> JikanListResponse<ForumTopicDTO> {
        return try await getCachedOrFetch(
            "\(baseURL)/anime/\(id)/forum?filter=\(filter)",
            as: JikanListResponse<ForumTopicDTO>.self)
    }

    func getAnimeVideos(_ id: Int) async throws -> JikanDataResponse<VideosDTO> {
        return try await getCachedOrFetch(
            "\(baseURL)/anime/\(id)/videos", as: JikanDataResponse<VideosDTO>.self)
    }

    func getAnimeVideosEpisodes(_ id: Int, page: Int) async throws -> JikanListResponse<
        EpisodeVideoDTO
    > {
        return try await getCachedOrFetch(
            "\(baseURL)/anime/\(id)/videos/episodes?page=\(page)",
            as: JikanListResponse<EpisodeVideoDTO>.self)
    }

    func getAnimePictures(_ id: Int) async throws -> JikanListResponse<PictureDTO> {
        return try await getCachedOrFetch(
            "\(baseURL)/anime/\(id)/pictures", as: JikanListResponse<PictureDTO>.self)
    }

    func getAnimeStatistics(_ id: Int) async throws -> JikanDataResponse<StatisticsDTO> {
        return try await getCachedOrFetch(
            "\(baseURL)/anime/\(id)/statistics", as: JikanDataResponse<StatisticsDTO>.self)
    }

    func getAnimeMoreInfo(_ id: Int) async throws -> JikanDataResponse<MoreInfoDTO> {
        return try await getCachedOrFetch(
            "\(baseURL)/anime/\(id)/moreinfo", as: JikanDataResponse<MoreInfoDTO>.self)
    }

    func getAnimeRecommendations(_ id: Int) async throws -> JikanListResponse<RecommendationDTO> {
        return try await getCachedOrFetch(
            "\(baseURL)/anime/\(id)/recommendations", as: JikanListResponse<RecommendationDTO>.self
        )
    }

    func getAnimeUserUpdates(_ id: Int, page: Int) async throws -> JikanListResponse<UserUpdateDTO>
    {
        return try await getCachedOrFetch(
            "\(baseURL)/anime/\(id)/userupdates?page=\(page)",
            as: JikanListResponse<UserUpdateDTO>.self)
    }

    func getAnimeReviews(_ id: Int, page: Int, preliminary: Bool, spoilers: Bool) async throws
        -> JikanListResponse<ReviewDTO>
    {
        return try await getCachedOrFetch(
            "\(baseURL)/anime/\(id)/reviews?page=\(page)&preliminary=\(preliminary)&spoilers=\(spoilers)",
            as: JikanListResponse<ReviewDTO>.self)
    }

    func getAnimeRelations(_ id: Int) async throws -> JikanListResponse<RelationDTO> {
        return try await getCachedOrFetch(
            "\(baseURL)/anime/\(id)/relations", as: JikanListResponse<RelationDTO>.self)
    }

    func getAnimeThemes(_ id: Int) async throws -> JikanDataResponse<ThemesDTO> {
        return try await getCachedOrFetch(
            "\(baseURL)/anime/\(id)/themes", as: JikanDataResponse<ThemesDTO>.self)
    }

    func getAnimeExternal(_ id: Int) async throws -> JikanListResponse<ExternalLinkDTO> {
        return try await getCachedOrFetch(
            "\(baseURL)/anime/\(id)/external", as: JikanListResponse<ExternalLinkDTO>.self)
    }

    func getAnimeStreaming(_ id: Int) async throws -> JikanListResponse<ExternalLinkDTO> {
        return try await getCachedOrFetch(
            "\(baseURL)/anime/\(id)/streaming", as: JikanListResponse<ExternalLinkDTO>.self)
    }

    func getAnimeGenres(filter: String? = nil) async throws -> JikanListResponse<GenreDTO> {
        var url = "\(baseURL)/genres/anime"
        if let filter = filter {
            url += "?filter=\(filter)"
        }
        return try await getCachedOrFetch(url, as: JikanListResponse<GenreDTO>.self)
    }

    func getRandomAnime() async throws -> AnimeResponse {
        return try await getCachedOrFetch("\(baseURL)/random/anime", as: AnimeResponse.self)
    }

    func getRandomManga() async throws -> RandomMangaResponse {
        return try await getCachedOrFetch("\(baseURL)/random/manga", as: RandomMangaResponse.self)
    }

    func getRandomCharacters() async throws -> RandomCharacterResponse {
        return try await getCachedOrFetch(
            "\(baseURL)/random/characters", as: RandomCharacterResponse.self)
    }

    func getRandomPeople() async throws -> RandomPersonResponse {
        return try await getCachedOrFetch("\(baseURL)/random/people", as: RandomPersonResponse.self)
    }

    func getRandomUsers() async throws -> RandomUserResponse {
        return try await getCachedOrFetch("\(baseURL)/random/users", as: RandomUserResponse.self)
    }

    func getRecentAnimeRecommendations(page: Int) async throws -> JikanListResponse<
        RecommendationDTO
    > {
        return try await getCachedOrFetch(
            "\(baseURL)/recommendations/anime?page=\(page)",
            as: JikanListResponse<RecommendationDTO>.self)
    }

    func getSeasonsList() async throws -> JikanListResponse<SeasonListDTO> {
        return try await getCachedOrFetch(
            "\(baseURL)/seasons", as: JikanListResponse<SeasonListDTO>.self)
    }

    func getWatchRecentEpisodes() async throws -> JikanListResponse<WatchEpisodeDTO> {
        return try await getCachedOrFetch(
            "\(baseURL)/watch/episodes", as: JikanListResponse<WatchEpisodeDTO>.self)
    }

    func getWatchPopularEpisodes() async throws -> JikanListResponse<WatchEpisodeDTO> {
        return try await getCachedOrFetch(
            "\(baseURL)/watch/episodes/popular", as: JikanListResponse<WatchEpisodeDTO>.self)
    }

    func getWatchRecentPromos(page: Int) async throws -> JikanListResponse<WatchPromoDTO> {
        return try await getCachedOrFetch(
            "\(baseURL)/watch/promos?page=\(page)", as: JikanListResponse<WatchPromoDTO>.self)
    }
}
