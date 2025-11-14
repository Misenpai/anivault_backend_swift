import Fluent
import Vapor

final class UserAnimeStatus: Model, Content, @unchecked Sendable {
    static let schema = "user_anime_status"

    @CompositeID
    var id: IDValue?

    @Field(key: "anime_name")
    var animeName: String

    @Field(key: "episodes_watched")
    var episodesWatched: Int

    @Field(key: "total_episodes")
    var totalEpisodes: Int

    @Field(key: "watch_status")
    var status: AnimeStatus

    @OptionalField(key: "score")
    var score: Double?

    @OptionalField(key: "started_watching_date")
    var startedDate: Date?

    @OptionalField(key: "completed_watching_date")
    var completedDate: Date?

    @Timestamp(key: "last_updated_at", on: .update)
    var updatedAt: Date?

    init() {}

    init(userEmail: String, malId: Int, animeName: String, totalEpisodes: Int, status: AnimeStatus)
    {
        self.id = .init(userID: userEmail, malID: malId)
        self.animeName = animeName
        self.episodesWatched = 0
        self.totalEpisodes = totalEpisodes
        self.status = status
    }

    final class IDValue: Fields, Hashable, @unchecked Sendable {
        @Parent(key: "user_email")
        var user: User

        @Field(key: "mal_id")
        var malId: Int

        init() {}

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
