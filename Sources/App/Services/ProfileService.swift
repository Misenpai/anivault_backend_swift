// Sources/App/Services/ProfileService.swift
import Vapor
import Fluent
import SQLKit

final class ProfileService {
    private let friendService: FriendService
    
    init(friendService: FriendService) {
        self.friendService = friendService
    }
    
    func getPublicProfile(
        username: String,
        viewerEmail: String?,
        on db: any Database
    ) async throws -> PublicProfileDTO {
        guard let user = try await User.query(on: db)
            .filter(\.$username == username)
            .first() else {
            throw Abort(.notFound, reason: "User not found")
        }
        
        let stats = try await getAnimeStats(userEmail: user.id!, on: db)
        
        var isFriend = false
        if let viewerEmail = viewerEmail {
            isFriend = try await friendService.areFriends(
                email1: viewerEmail,
                email2: user.id!,
                on: db
            )
        }
        
        return PublicProfileDTO(
            username: user.username,
            animeStats: stats,
            isFriend: isFriend
        )
    }
    
    func getAnimeStats(userEmail: String, on db: any Database) async throws -> AnimeStatsDTO {
        guard let sql = db as? any SQLDatabase else {
            throw Abort(.internalServerError, reason: "Database doesn't support SQL")
        }
        
        struct StatsRow: Decodable {
            let totalAnimeEntries: Int?
            let completedCount: Int?
            let currentlyWatching: Int?
            let planToWatchCount: Int?
            let droppedCount: Int?
            let onHoldCount: Int?
            let totalEpisodesWatched: Int?
            
            enum CodingKeys: String, CodingKey {
                case totalAnimeEntries = "total_anime_entries"
                case completedCount = "completed_count"
                case currentlyWatching = "currently_watching"
                case planToWatchCount = "plan_to_watch_count"
                case droppedCount = "dropped_count"
                case onHoldCount = "on_hold_count"
                case totalEpisodesWatched = "total_episodes_watched"
            }
        }
        
        let result = try await sql.raw("""
            SELECT * FROM v_user_anime_stats WHERE user_email = \(bind: userEmail)
        """).first(decoding: StatsRow.self)
        
        return AnimeStatsDTO(
            watching: result?.currentlyWatching ?? 0,
            completed: result?.completedCount ?? 0,
            planToWatch: result?.planToWatchCount ?? 0,
            dropped: result?.droppedCount ?? 0,
            onHold: result?.onHoldCount ?? 0,
            totalAnime: result?.totalAnimeEntries ?? 0,
            totalEpisodesWatched: result?.totalEpisodesWatched ?? 0,
            averageScore: nil  // Not in the view, calculate separately if needed
        )
    }
}