//
//  AnimeDTO.swift
//  anivault_backend
//
//  Created by Sumit Sinha on 08/11/25.
//

import Vapor

struct UserAnimeStatusDTO: Content {
    let userEmail: String
    let malId: Int
    let animeName: String
    let episodesWatched: Int
    let totalEpisodes: Int
    let status: String
    let score: Double?
    let startedDate: Date?
    let completedDate: Date?
    let lastUpdated: Date?
    
    enum CodingKeys: String, CodingKey {
        case userEmail = "user_email"
        case malId = "mal_id"
        case animeName = "anime_name"
        case episodesWatched = "episodes_watched"
        case totalEpisodes = "total_episodes"
        case status
        case score
        case startedDate = "started_date"
        case completedDate = "completed_date"
        case lastUpdated = "last_updated"
    }
}

struct AddAnimeStatusRequest: Content {
    let malId: Int
    let animeName: String
    let totalEpisodes: Int
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case malId = "mal_id"
        case animeName = "anime_name"
        case totalEpisodes = "total_episodes"
        case status
    }
}

struct UpdateAnimeStatusRequest: Content {
    let malId: Int
    let episodesWatched: Int?
    let status: String?
    let score: Double?
    
    enum CodingKeys: String, CodingKey {
        case malId = "mal_id"
        case episodesWatched = "episodes_watched"
        case status
        case score
    }
}

struct AnimeStatusSummaryDTO: Content {
    let malId: Int
    let animeName: String
    let status: String
    let progress: String // "5/12 episodes"
    let progressPercentage: Double // 41.67
    
    enum CodingKeys: String, CodingKey {
        case malId = "mal_id"
        case animeName = "anime_name"
        case status
        case progress
        case progressPercentage = "progress_percentage"
    }
}

struct AnimeStatsDTO: Content {
    let watching: Int
    let completed: Int
    let planToWatch: Int
    let dropped: Int
    let onHold: Int
    let totalAnime: Int
    let totalEpisodesWatched: Int
    let averageScore: Double?
    
    enum CodingKeys: String, CodingKey {
        case watching
        case completed
        case planToWatch = "plan_to_watch"
        case dropped
        case onHold = "on_hold"
        case totalAnime = "total_anime"
        case totalEpisodesWatched = "total_episodes_watched"
        case averageScore = "average_score"
    }
}

struct BulkUpdateStatusRequest: Content {
    let malIds: [Int]
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case malIds = "mal_ids"
        case status
    }
}


extension UserAnimeStatus {
    func toDTO() -> UserAnimeStatusDTO {
        return UserAnimeStatusDTO(
            userEmail: self.id?.user.id ?? "",
            malId: self.id?.malId ?? 0,
            animeName: self.animeName,
            episodesWatched: self.episodesWatched,  // Changed from totalWatchedEpisodes
            totalEpisodes: self.totalEpisodes,
            status: self.status.rawValue,
            score: self.score,
            startedDate: self.startedDate,
            completedDate: self.completedDate,
            lastUpdated: self.updatedAt
        )
    }
    
    func toSummaryDTO() -> AnimeStatusSummaryDTO {
        let progress = "\(episodesWatched)/\(totalEpisodes) episodes"  // Changed
        let percentage = totalEpisodes > 0 ?
            (Double(episodesWatched) / Double(totalEpisodes)) * 100 : 0  // Changed
        
        return AnimeStatusSummaryDTO(
            malId: self.id?.malId ?? 0,
            animeName: self.animeName,
            status: self.status.rawValue,
            progress: progress,
            progressPercentage: percentage
        )
    }
}

struct UserAnimeListResponse: Content {
    let success: Bool
    let data: [UserAnimeStatusDTO]
    let count: Int
}

struct SingleAnimeStatusResponse: Content {
    let success: Bool
    let data: UserAnimeStatusDTO
}

struct AnimeStatsResponse: Content {
    let success: Bool
    let stats: AnimeStatsDTO
}

struct RecentlyUpdatedResponse: Content {
    let success: Bool
    let data: [UserAnimeStatusDTO]
    let limit: Int
}

struct ProgressReportDTO: Content {
    let almostCompleted: [AnimeStatusSummaryDTO]
    let watching: [AnimeStatusSummaryDTO]
    let recentlyCompleted: [UserAnimeStatusDTO]
}
