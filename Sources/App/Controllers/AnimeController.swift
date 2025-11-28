import Fluent
import Vapor

struct AnimeController: RouteCollection {
    private let jikanService: JikanService
    private let animeService: AnimeService

    init(jikanService: JikanService, animeService: AnimeService) {
        self.jikanService = jikanService
        self.animeService = animeService
    }

    func boot(routes: any RoutesBuilder) throws {
        let anime = routes.grouped("anime")
        let protected = anime.grouped(JWTAuthenticationMiddleware())

        protected.get(":id", use: getAnimeById)
        protected.get(":id", "full", use: getAnimeFullById)
        protected.get(":id", "characters", use: getAnimeCharacters)
        protected.get(":id", "staff", use: getAnimeStaff)
        protected.get(":id", "episodes", use: getAnimeEpisodes)
        protected.get(":id", "episodes", ":episode", use: getAnimeEpisodeById)
        protected.get(":id", "news", use: getAnimeNews)
        protected.get(":id", "forum", use: getAnimeForum)
        protected.get(":id", "videos", use: getAnimeVideos)
        protected.get(":id", "videos", "episodes", use: getAnimeVideosEpisodes)
        protected.get(":id", "pictures", use: getAnimePictures)
        protected.get(":id", "statistics", use: getAnimeStatistics)
        protected.get(":id", "moreinfo", use: getAnimeMoreInfo)
        protected.get(":id", "recommendations", use: getAnimeRecommendations)
        protected.get(":id", "userupdates", use: getAnimeUserUpdates)
        protected.get(":id", "reviews", use: getAnimeReviews)
        protected.get(":id", "relations", use: getAnimeRelations)
        protected.get(":id", "themes", use: getAnimeThemes)
        protected.get(":id", "external", use: getAnimeExternal)
        protected.get(":id", "streaming", use: getAnimeStreaming)
        protected.get("search", use: searchAnime)
        protected.get("season", "now", use: getCurrentSeason)
        protected.get("season", "upcoming", use: getUpcomingSeason)
        protected.get("season", ":year", ":season", use: getSeasonAnime)
        protected.get("top", use: getTopAnime)

        protected.get("genres", "anime", use: getAnimeGenres)
        protected.get("random", "anime", use: getRandomAnime)
        protected.get("random", "manga", use: getRandomManga)
        protected.get("random", "characters", use: getRandomCharacters)
        protected.get("random", "people", use: getRandomPeople)
        protected.get("random", "users", use: getRandomUsers)
        protected.get("recommendations", "anime", use: getRecentAnimeRecommendations)
        protected.get("seasons", use: getSeasonsList)
        protected.get("watch", "episodes", use: getWatchRecentEpisodes)
        protected.get("watch", "episodes", "popular", use: getWatchPopularEpisodes)
        protected.get("watch", "promos", use: getWatchRecentPromos)

        let userAnime = protected.grouped("user")
        userAnime.post(use: addAnimeToList)
        userAnime.put(use: updateAnimeStatus)
        userAnime.delete(":malId", use: deleteAnimeFromList)
        userAnime.get("status", ":status", use: getAnimeByStatus)
        userAnime.get(":malId", use: checkAnimeStatus)
    }

    private func getAnimeGenres(req: Request) async throws -> JikanListResponse<GenreDTO> {
        let filter = req.query[String.self, at: "filter"]
        return try await jikanService.getAnimeGenres(filter: filter)
    }

    private func getRandomAnime(req: Request) async throws -> AnimeResponse {
        return try await jikanService.getRandomAnime()
    }

    private func getRandomManga(req: Request) async throws -> RandomMangaResponse {
        return try await jikanService.getRandomManga()
    }

    private func getRandomCharacters(req: Request) async throws -> RandomCharacterResponse {
        return try await jikanService.getRandomCharacters()
    }

    private func getRandomPeople(req: Request) async throws -> RandomPersonResponse {
        return try await jikanService.getRandomPeople()
    }

    private func getRandomUsers(req: Request) async throws -> RandomUserResponse {
        return try await jikanService.getRandomUsers()
    }

    private func getRecentAnimeRecommendations(req: Request) async throws -> JikanListResponse<
        RecommendationDTO
    > {
        let page = req.query[Int.self, at: "page"] ?? 1
        return try await jikanService.getRecentAnimeRecommendations(page: page)
    }

    private func getSeasonsList(req: Request) async throws -> JikanListResponse<SeasonListDTO> {
        return try await jikanService.getSeasonsList()
    }

    private func getWatchRecentEpisodes(req: Request) async throws -> JikanListResponse<
        WatchEpisodeDTO
    > {
        return try await jikanService.getWatchRecentEpisodes()
    }

    private func getWatchPopularEpisodes(req: Request) async throws -> JikanListResponse<
        WatchEpisodeDTO
    > {
        return try await jikanService.getWatchPopularEpisodes()
    }

    private func getWatchRecentPromos(req: Request) async throws -> JikanListResponse<WatchPromoDTO>
    {
        let page = req.query[Int.self, at: "page"] ?? 1
        return try await jikanService.getWatchRecentPromos(page: page)
    }

    private func getAnimeFullById(req: Request) async throws -> AnimeResponse {
        guard let id = req.parameters.get("id", as: Int.self) else {
            throw Abort(.badRequest, reason: "Invalid anime ID")
        }
        return try await jikanService.getAnimeFullById(id)
    }

    private func getAnimeCharacters(req: Request) async throws -> JikanListResponse<CharacterDTO> {
        guard let id = req.parameters.get("id", as: Int.self) else {
            throw Abort(.badRequest, reason: "Invalid anime ID")
        }
        return try await jikanService.getAnimeCharacters(id)
    }

    private func getAnimeStaff(req: Request) async throws -> JikanListResponse<StaffDTO> {
        guard let id = req.parameters.get("id", as: Int.self) else {
            throw Abort(.badRequest, reason: "Invalid anime ID")
        }
        return try await jikanService.getAnimeStaff(id)
    }

    private func getAnimeEpisodes(req: Request) async throws -> JikanListResponse<EpisodeDTO> {
        guard let id = req.parameters.get("id", as: Int.self) else {
            throw Abort(.badRequest, reason: "Invalid anime ID")
        }
        let page = req.query[Int.self, at: "page"] ?? 1
        return try await jikanService.getAnimeEpisodes(id, page: page)
    }

    private func getAnimeEpisodeById(req: Request) async throws -> JikanDataResponse<EpisodeDTO> {
        guard let id = req.parameters.get("id", as: Int.self),
            let episode = req.parameters.get("episode", as: Int.self)
        else {
            throw Abort(.badRequest, reason: "Invalid ID or episode number")
        }
        return try await jikanService.getAnimeEpisodeById(id, episode: episode)
    }

    private func getAnimeNews(req: Request) async throws -> JikanListResponse<NewsDTO> {
        guard let id = req.parameters.get("id", as: Int.self) else {
            throw Abort(.badRequest, reason: "Invalid anime ID")
        }
        let page = req.query[Int.self, at: "page"] ?? 1
        return try await jikanService.getAnimeNews(id, page: page)
    }

    private func getAnimeForum(req: Request) async throws -> JikanListResponse<ForumTopicDTO> {
        guard let id = req.parameters.get("id", as: Int.self) else {
            throw Abort(.badRequest, reason: "Invalid anime ID")
        }
        let filter = req.query[String.self, at: "filter"] ?? "all"
        return try await jikanService.getAnimeForum(id, filter: filter)
    }

    private func getAnimeVideos(req: Request) async throws -> JikanDataResponse<VideosDTO> {
        guard let id = req.parameters.get("id", as: Int.self) else {
            throw Abort(.badRequest, reason: "Invalid anime ID")
        }
        return try await jikanService.getAnimeVideos(id)
    }

    private func getAnimeVideosEpisodes(req: Request) async throws -> JikanListResponse<
        EpisodeVideoDTO
    > {
        guard let id = req.parameters.get("id", as: Int.self) else {
            throw Abort(.badRequest, reason: "Invalid anime ID")
        }
        let page = req.query[Int.self, at: "page"] ?? 1
        return try await jikanService.getAnimeVideosEpisodes(id, page: page)
    }

    private func getAnimePictures(req: Request) async throws -> JikanListResponse<PictureDTO> {
        guard let id = req.parameters.get("id", as: Int.self) else {
            throw Abort(.badRequest, reason: "Invalid anime ID")
        }
        return try await jikanService.getAnimePictures(id)
    }

    private func getAnimeStatistics(req: Request) async throws -> JikanDataResponse<StatisticsDTO> {
        guard let id = req.parameters.get("id", as: Int.self) else {
            throw Abort(.badRequest, reason: "Invalid anime ID")
        }
        return try await jikanService.getAnimeStatistics(id)
    }

    private func getAnimeMoreInfo(req: Request) async throws -> JikanDataResponse<MoreInfoDTO> {
        guard let id = req.parameters.get("id", as: Int.self) else {
            throw Abort(.badRequest, reason: "Invalid anime ID")
        }
        return try await jikanService.getAnimeMoreInfo(id)
    }

    private func getAnimeRecommendations(req: Request) async throws -> JikanListResponse<
        RecommendationDTO
    > {
        guard let id = req.parameters.get("id", as: Int.self) else {
            throw Abort(.badRequest, reason: "Invalid anime ID")
        }
        return try await jikanService.getAnimeRecommendations(id)
    }

    private func getAnimeUserUpdates(req: Request) async throws -> JikanListResponse<UserUpdateDTO>
    {
        guard let id = req.parameters.get("id", as: Int.self) else {
            throw Abort(.badRequest, reason: "Invalid anime ID")
        }
        let page = req.query[Int.self, at: "page"] ?? 1
        return try await jikanService.getAnimeUserUpdates(id, page: page)
    }

    private func getAnimeReviews(req: Request) async throws -> JikanListResponse<ReviewDTO> {
        guard let id = req.parameters.get("id", as: Int.self) else {
            throw Abort(.badRequest, reason: "Invalid anime ID")
        }
        let page = req.query[Int.self, at: "page"] ?? 1
        let preliminary = req.query[Bool.self, at: "preliminary"] ?? false
        let spoilers = req.query[Bool.self, at: "spoilers"] ?? false
        return try await jikanService.getAnimeReviews(
            id, page: page, preliminary: preliminary, spoilers: spoilers)
    }

    private func getAnimeRelations(req: Request) async throws -> JikanListResponse<RelationDTO> {
        guard let id = req.parameters.get("id", as: Int.self) else {
            throw Abort(.badRequest, reason: "Invalid anime ID")
        }
        return try await jikanService.getAnimeRelations(id)
    }

    private func getAnimeThemes(req: Request) async throws -> JikanDataResponse<ThemesDTO> {
        guard let id = req.parameters.get("id", as: Int.self) else {
            throw Abort(.badRequest, reason: "Invalid anime ID")
        }
        return try await jikanService.getAnimeThemes(id)
    }

    private func getAnimeExternal(req: Request) async throws -> JikanListResponse<ExternalLinkDTO> {
        guard let id = req.parameters.get("id", as: Int.self) else {
            throw Abort(.badRequest, reason: "Invalid anime ID")
        }
        return try await jikanService.getAnimeExternal(id)
    }

    private func getAnimeStreaming(req: Request) async throws -> JikanListResponse<ExternalLinkDTO>
    {
        guard let id = req.parameters.get("id", as: Int.self) else {
            throw Abort(.badRequest, reason: "Invalid anime ID")
        }
        return try await jikanService.getAnimeStreaming(id)
    }

    private func getAnimeById(req: Request) async throws -> AnimeResponse {
        guard let id = req.parameters.get("id", as: Int.self) else {
            throw Abort(.badRequest, reason: "Invalid anime ID")
        }
        return try await jikanService.getAnimeById(id)
    }

    private func searchAnime(req: Request) async throws -> SeasonAnimeResponse {
        guard let query = req.query[String.self, at: "q"] else {
            throw Abort(.badRequest, reason: "Search query required")
        }
        let page = req.query[Int.self, at: "page"] ?? 1
        let limit = req.query[Int.self, at: "limit"] ?? 25

        return try await jikanService.searchAnime(query: query, page: page, limit: limit)
    }

    private func getCurrentSeason(req: Request) async throws -> SeasonAnimeResponse {
        let page = req.query[Int.self, at: "page"] ?? 1
        let limit = req.query[Int.self, at: "limit"] ?? 25

        return try await jikanService.getCurrentSeasonAnime(page: page, limit: limit)
    }

    private func getUpcomingSeason(req: Request) async throws -> SeasonAnimeResponse {
        let page = req.query[Int.self, at: "page"] ?? 1
        let limit = req.query[Int.self, at: "limit"] ?? 25

        return try await jikanService.getUpcomingSeasonAnime(page: page, limit: limit)
    }

    private func getSeasonAnime(req: Request) async throws -> SeasonAnimeResponse {
        guard let year = req.parameters.get("year", as: Int.self),
            let season = req.parameters.get("season")
        else {
            throw Abort(.badRequest, reason: "Year and season required")
        }
        let page = req.query[Int.self, at: "page"] ?? 1

        return try await jikanService.getSeasonAnime(year: year, season: season, page: page)
    }

    private func getTopAnime(req: Request) async throws -> SeasonAnimeResponse {
        let page = req.query[Int.self, at: "page"] ?? 1
        let limit = req.query[Int.self, at: "limit"] ?? 25

        return try await jikanService.getTopAnime(page: page, limit: limit)
    }

    private func addAnimeToList(req: Request) async throws -> UserAnimeStatus {
        let user = try req.auth.require(User.self)
        let request = try req.content.decode(AddAnimeStatusRequest.self)

        return try await animeService.addAnimeStatus(
            userEmail: user.id!,
            malId: request.malId,
            animeName: request.animeName,
            totalEpisodes: request.totalEpisodes,
            status: AnimeStatus(rawValue: request.status) ?? .planToWatch,
            on: req.db
        )
    }

    private func updateAnimeStatus(req: Request) async throws -> UserAnimeStatus {
        let user = try req.auth.require(User.self)
        let request = try req.content.decode(UpdateAnimeStatusRequest.self)

        return try await animeService.updateAnimeStatus(
            userEmail: user.id!,
            malId: request.malId,
            watchedEpisodes: request.episodesWatched,
            status: request.status.flatMap { AnimeStatus(rawValue: $0) },
            score: nil,
            on: req.db
        )
    }

    private func deleteAnimeFromList(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        guard let malId = req.parameters.get("malId", as: Int.self) else {
            throw Abort(.badRequest, reason: "Invalid MAL ID")
        }

        try await animeService.removeAnimeStatus(userEmail: user.id!, malId: malId, on: req.db)
        return .noContent
    }

    private func getAnimeByStatus(req: Request) async throws -> [UserAnimeStatus] {
        let user = try req.auth.require(User.self)
        guard let statusString = req.parameters.get("status"),
            let status = AnimeStatus(rawValue: statusString)
        else {
            throw Abort(.badRequest, reason: "Invalid status")
        }

        return try await animeService.getUserAnimeByStatus(
            userEmail: user.id!,
            status: status,
            on: req.db
        )
    }

    private func checkAnimeStatus(req: Request) async throws -> UserAnimeStatus {
        let user = try req.auth.require(User.self)
        guard let malId = req.parameters.get("malId", as: Int.self) else {
            throw Abort(.badRequest, reason: "Invalid MAL ID")
        }

        guard
            let anime = try await animeService.getAnimeStatus(
                userEmail: user.id!,
                malId: malId,
                on: req.db
            )
        else {
            throw Abort(.notFound, reason: "Anime not in your list")
        }

        return anime
    }
}
