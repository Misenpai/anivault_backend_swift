import Fluent

struct CreateUserAnimeStatus: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("user_anime_status")
            .field("user_email", .string, .required)
            .field("mal_id", .int, .required)
            .field("anime_name", .string, .required)
            .field("episodes_watched", .int, .required)
            .field("total_episodes", .int, .required)
            .field("watch_status", .string, .required)
            .field("score", .double)
            .field("started_watching_date", .date)
            .field("completed_watching_date", .date)
            .field("last_updated_at", .datetime)
            .compositePrimaryKey(on: "user_email", "mal_id")
            .foreignKey("user_email", references: "users", "email", onDelete: .cascade)
            .create()

        try await database.schema("user_anime_status")
            .createIndex(on: "user_email")
            .createIndex(on: "mal_id")
            .createIndex(on: "watch_status")
            .createIndex(on: "anime_name")
            .createIndex(on: "last_updated_at")
            .update()

        try await database.raw(
            """
                ALTER TABLE user_anime_status 
                ADD CONSTRAINT valid_watch_status 
                CHECK (watch_status IN ('Watching', 'Completed', 'PlanToWatch', 'Dropped', 'OnHold'))
            """
        ).run()

        try await database.raw(
            """
                ALTER TABLE user_anime_status 
                ADD CONSTRAINT valid_episodes_count 
                CHECK (episodes_watched >= 0 AND episodes_watched <= total_episodes)
            """
        ).run()
    }

    func revert(on database: Database) async throws {
        try await database.schema("user_anime_status").delete()
    }
}
