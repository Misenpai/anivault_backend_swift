//
//  UserAnimeStatus.swift
//  anivault_backend
//
//  Created by Sumit Sinha on 08/11/25.
//

import Fluent
import Vapor

final class UserAnimeStatus: Model, Content {
    static let schema = "user_anime_status"

    @CompositeID
    var id: IDValue?

    @Field(key: "anime_name")
    var animeName: String

    @Field(key: "total_watched_episodes")
    var totalWatchedEpisodes: Int

    @Field(key: "total_episodes")
    var totalEpisodes: Int

    @Field(key: "status")
    var status: AnimeStatus

    @Field(key: "score")
    var score: Double?

    @Field(key: "started_date")
    var startedDate: Date?

    @Field(key: "completed_date")
    var completedDate: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() { }

    init(userEmail: String, malId: Int, animeName: String, totalEpisodes: Int, status: AnimeStatus) {
        self.id = .init(userID: userEmail, malID: malId)
        self.animeName = animeName
        self.totalWatchedEpisodes = 0
        self.totalEpisodes = totalEpisodes
        self.status = status
    }

    final class IDValue: Fields, Hashable {
        @Parent(key: "user_email")
        var user: User

        @Field(key: "mal_id")
        var malId: Int

        init() { }

        init(userID: String, malID: Int) {
            self.$user.id = userID
            self.malId = malID
        }

        static func == (lhs: IDValue, rhs: IDValue) -> Bool {
            lhs.user.id == rhs.user.id && lhs.malId == rhs.malId
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(self.user.id)
            hasher.combine(self.malId)
        }
    }
}

enum AnimeStatus: String, Codable, CaseIterable {
    case watching = "Watching"
    case completed = "Completed"
    case planToWatch = "PlanToWatch"
    case dropped = "Dropped"
    case onHold = "OnHold"
}
