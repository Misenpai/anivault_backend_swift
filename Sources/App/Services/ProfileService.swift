//
//  ProfileService.swift
//  anivault_backend
//
//  Created by Sumit Sinha on 09/11/25.
//

import Vapor
import Fluent

final class ProfileService {
    private let friendService: FriendService
    
    init(friendService: FriendService) {
        self.friendService = friendService
    }
    
    func getPublicProfile(
        username: String,
        viewerEmail: String?,
        on db: Database
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
    
    func getAnimeStats(userEmail: String, on db: Database) async throws -> AnimeStatsDTO {
        struct StatsRow: Decodable {
            let watching: Int?
            let completed: Int?
            let planToWatch: Int?
            let dropped: Int?
            let onHold: Int?
            
            enum CodingKeys: String, CodingKey {
                case watching = "currently_watching"
                case completed = "completed_count"
                case planToWatch = "plan_to_watch_count"
                case dropped = "dropped_count"
                case onHold = "on_hold_count"
            }
        }
        
        let result = try await db.raw("""
            SELECT * FROM v_user_anime_stats WHERE user_email = \(bind: userEmail)
        """).first(decoding: StatsRow.self)
        
        return AnimeStatsDTO(
            watching: result?.watching ?? 0,
            completed: result?.completed ?? 0,
            planToWatch: result?.planToWatch ?? 0,
            dropped: result?.dropped ?? 0,
            onHold: result?.onHold ?? 0
        )
    }
}