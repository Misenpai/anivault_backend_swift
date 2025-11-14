import Vapor

struct AnimeResponse: Content {
    let data: AnimeDTO
}

struct SeasonAnimeResponse: Content {
    let pagination: PaginationDTO
    let data: [AnimeDTO]
}

struct PaginationDTO: Content {
    let lastVisiblePage: Int
    let hasNextPage: Bool
    let currentPage: Int

    enum CodingKeys: String, CodingKey {
        case lastVisiblePage = "last_visible_page"
        case hasNextPage = "has_next_page"
        case currentPage = "current_page"
    }
}

struct AnimeDTO: Content {
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

struct ImagesDTO: Content {
    let jpg: ImageUrlsDTO
    let webp: ImageUrlsDTO
}

struct ImageUrlsDTO: Content {
    let imageUrl: String
    let smallImageUrl: String?
    let largeImageUrl: String?

    enum CodingKeys: String, CodingKey {
        case imageUrl = "image_url"
        case smallImageUrl = "small_image_url"
        case largeImageUrl = "large_image_url"
    }
}

struct AiredDTO: Content {
    let from: String?
    let to: String?
    let string: String?
}

struct NamedResourceDTO: Content {
    let malId: Int
    let name: String

    enum CodingKeys: String, CodingKey {
        case malId = "mal_id"
        case name
    }
}
