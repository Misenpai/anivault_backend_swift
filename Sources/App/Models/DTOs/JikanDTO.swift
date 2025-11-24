import Vapor

struct AnimeResponse: Content, Sendable {
    let data: AnimeDTO
}

struct SeasonAnimeResponse: Content, Sendable {
    let pagination: PaginationDTO
    let data: [AnimeDTO]
}

struct PaginationDTO: Content, Sendable {
    let lastVisiblePage: Int
    let hasNextPage: Bool
    let currentPage: Int

    enum CodingKeys: String, CodingKey {
        case lastVisiblePage = "last_visible_page"
        case hasNextPage = "has_next_page"
        case currentPage = "current_page"
    }
}

struct AnimeDTO: Content, Sendable {
    let malId: Int
    let url: String?
    let images: ImagesDTO
    let title: String
    let titleEnglish: String?
    let titleJapanese: String?
    let type: String?
    let source: String?
    let episodes: Int?
    let status: String
    let airing: Bool
    let aired: AiredDTO?
    let duration: String?
    let rating: String?
    let score: Double?
    let scoredBy: Int?
    let rank: Int?
    let synopsis: String?
    let season: String?
    let year: Int?
    let producers: [NamedResourceDTO]?
    let studios: [NamedResourceDTO]?
    let genres: [NamedResourceDTO]?
    let themes: [NamedResourceDTO]?

    enum CodingKeys: String, CodingKey {
        case malId = "mal_id"
        case url, images, title
        case titleEnglish = "title_english"
        case titleJapanese = "title_japanese"
        case type, source, episodes, status, airing, aired, duration, rating, score
        case scoredBy = "scored_by"
        case rank, synopsis, season, year, producers, studios, genres, themes
    }
}

struct ImagesDTO: Content, Sendable {
    let jpg: ImageUrlsDTO
    let webp: ImageUrlsDTO
}

struct ImageUrlsDTO: Content, Sendable {
    let imageUrl: String
    let smallImageUrl: String?
    let largeImageUrl: String?

    enum CodingKeys: String, CodingKey {
        case imageUrl = "image_url"
        case smallImageUrl = "small_image_url"
        case largeImageUrl = "large_image_url"
    }
}

struct AiredDTO: Content, Sendable {
    let from: String?
    let to: String?
    let string: String?
}

struct NamedResourceDTO: Content, Sendable {
    let malId: Int
    let name: String

    enum CodingKeys: String, CodingKey {
        case malId = "mal_id"
        case name
    }
}

// MARK: - Generic Responses

struct JikanListResponse<T: Content & Sendable>: Content, Sendable {
    let data: [T]
    let pagination: PaginationDTO?
}

struct JikanDataResponse<T: Content & Sendable>: Content, Sendable {
    let data: T
}

// MARK: - Character DTOs

struct CharacterDTO: Content, Sendable {
    let character: CharacterMetaDTO
    let role: String
    let favorites: Int
    let voiceActors: [VoiceActorDTO]

    enum CodingKeys: String, CodingKey {
        case character
        case role
        case favorites
        case voiceActors = "voice_actors"
    }
}

struct CharacterMetaDTO: Content, Sendable {
    let malId: Int
    let url: String
    let images: ImagesDTO
    let name: String

    enum CodingKeys: String, CodingKey {
        case malId = "mal_id"
        case url
        case images
        case name
    }
}

struct VoiceActorDTO: Content, Sendable {
    let person: PersonMetaDTO
    let language: String
}

struct PersonMetaDTO: Content, Sendable {
    let malId: Int
    let url: String
    let images: PeopleImagesDTO
    let name: String

    enum CodingKeys: String, CodingKey {
        case malId = "mal_id"
        case url
        case images
        case name
    }
}

struct PeopleImagesDTO: Content, Sendable {
    let jpg: ImageUrlsDTO
}

// MARK: - Staff DTOs

struct StaffDTO: Content, Sendable {
    let person: PersonMetaDTO
    let positions: [String]
}

// MARK: - Episode DTOs

struct EpisodeDTO: Content, Sendable {
    let malId: Int
    let url: String?
    let title: String
    let titleJapanese: String?
    let titleRomanji: String?
    let duration: Int?
    let aired: String?
    let filler: Bool
    let recap: Bool
    let synopsis: String?

    enum CodingKeys: String, CodingKey {
        case malId = "mal_id"
        case url
        case title
        case titleJapanese = "title_japanese"
        case titleRomanji = "title_romanji"
        case duration
        case aired
        case filler
        case recap
        case synopsis
    }
}

// MARK: - News DTOs

struct NewsDTO: Content, Sendable {
    let malId: Int?
    let url: String?
    let title: String
    let date: String?
    let authorUsername: String?
    let authorUrl: String?
    let forumUrl: String?
    let images: ImagesDTO?
    let comments: Int?
    let excerpt: String?

    enum CodingKeys: String, CodingKey {
        case malId = "mal_id"
        case url
        case title
        case date
        case authorUsername = "author_username"
        case authorUrl = "author_url"
        case forumUrl = "forum_url"
        case images
        case comments
        case excerpt
    }
}

// MARK: - Forum DTOs

struct ForumTopicDTO: Content, Sendable {
    let malId: Int
    let url: String
    let title: String
    let date: String
    let authorUsername: String
    let authorUrl: String
    let comments: Int
    let lastComment: ForumLastCommentDTO?

    enum CodingKeys: String, CodingKey {
        case malId = "mal_id"
        case url
        case title
        case date
        case authorUsername = "author_username"
        case authorUrl = "author_url"
        case comments
        case lastComment = "last_comment"
    }
}

struct ForumLastCommentDTO: Content, Sendable {
    let url: String
    let authorUsername: String
    let authorUrl: String
    let date: String

    enum CodingKeys: String, CodingKey {
        case url
        case authorUsername = "author_username"
        case authorUrl = "author_url"
        case date
    }
}

// MARK: - Video DTOs

struct VideosDTO: Content, Sendable {
    let promo: [PromoVideoDTO]
    let episodes: [EpisodeVideoDTO]
    let musicVideos: [MusicVideoDTO]

    enum CodingKeys: String, CodingKey {
        case promo
        case episodes
        case musicVideos = "music_videos"
    }
}

struct PromoVideoDTO: Content, Sendable {
    let title: String
    let trailer: TrailerDTO
}

struct TrailerDTO: Content, Sendable {
    let youtubeId: String?
    let url: String?
    let embedUrl: String?
    let images: ImageUrlsDTO?

    enum CodingKeys: String, CodingKey {
        case youtubeId = "youtube_id"
        case url
        case embedUrl = "embed_url"
        case images
    }
}

struct EpisodeVideoDTO: Content, Sendable {
    let malId: Int
    let title: String
    let episode: String
    let url: String?
    let images: ImageUrlsDTO?

    enum CodingKeys: String, CodingKey {
        case malId = "mal_id"
        case title
        case episode
        case url
        case images
    }
}

struct MusicVideoDTO: Content, Sendable {
    let title: String
    let video: TrailerDTO
    let meta: MusicVideoMetaDTO
}

struct MusicVideoMetaDTO: Content, Sendable {
    let title: String?
    let author: String?
}

// MARK: - Picture DTOs

struct PictureDTO: Content, Sendable {
    let jpg: ImageUrlsDTO
    let webp: ImageUrlsDTO
}

// MARK: - Statistics DTOs

struct StatisticsDTO: Content, Sendable {
    let watching: Int
    let completed: Int
    let onHold: Int
    let dropped: Int
    let planToWatch: Int
    let total: Int
    let scores: [ScoreStatsDTO]

    enum CodingKeys: String, CodingKey {
        case watching
        case completed
        case onHold = "on_hold"
        case dropped
        case planToWatch = "plan_to_watch"
        case total
        case scores
    }
}

struct ScoreStatsDTO: Content, Sendable {
    let score: Int
    let votes: Int
    let percentage: Double
}

// MARK: - More Info DTOs

struct MoreInfoDTO: Content, Sendable {
    let moreinfo: String?
}

// MARK: - Recommendation DTOs

struct RecommendationDTO: Content, Sendable {
    let entry: AnimeMetaDTO
    let url: String?
    let votes: Int
}

struct AnimeMetaDTO: Content, Sendable {
    let malId: Int
    let url: String
    let images: ImagesDTO
    let title: String

    enum CodingKeys: String, CodingKey {
        case malId = "mal_id"
        case url
        case images
        case title
    }
}

// MARK: - User Update DTOs

struct UserUpdateDTO: Content, Sendable {
    let user: UserMetaDTO
    let score: Int?
    let status: String
    let episodesSeen: Int?
    let episodesTotal: Int?
    let date: String

    enum CodingKeys: String, CodingKey {
        case user
        case score
        case status
        case episodesSeen = "episodes_seen"
        case episodesTotal = "episodes_total"
        case date
    }
}

struct UserMetaDTO: Content, Sendable {
    let username: String
    let url: String
    let images: UserImagesDTO?
}

struct UserImagesDTO: Content, Sendable {
    let jpg: ImageUrlsDTO?
    let webp: ImageUrlsDTO?
}

// MARK: - Review DTOs

struct ReviewDTO: Content, Sendable {
    let malId: Int
    let url: String
    let type: String
    let reactions: ReviewReactionsDTO
    let date: String
    let review: String
    let score: Int
    let tags: [String]
    let isSpoiler: Bool
    let isPreliminary: Bool
    let user: UserMetaDTO

    enum CodingKeys: String, CodingKey {
        case malId = "mal_id"
        case url
        case type
        case reactions
        case date
        case review
        case score
        case tags
        case isSpoiler = "is_spoiler"
        case isPreliminary = "is_preliminary"
        case user
    }
}

struct ReviewReactionsDTO: Content, Sendable {
    let overall: Int
    let nice: Int
    let loveIt: Int
    let funny: Int
    let confusing: Int
    let informative: Int
    let wellWritten: Int
    let creative: Int

    enum CodingKeys: String, CodingKey {
        case overall
        case nice
        case loveIt = "love_it"
        case funny
        case confusing
        case informative
        case wellWritten = "well_written"
        case creative
    }
}

// MARK: - Relation DTOs

struct RelationDTO: Content, Sendable {
    let relation: String
    let entry: [AnimeMetaDTO]
}

// MARK: - Theme DTOs

struct ThemesDTO: Content, Sendable {
    let openings: [String]
    let endings: [String]
}

// MARK: - External DTOs

struct ExternalLinkDTO: Content, Sendable {
    let name: String
    let url: String
}
