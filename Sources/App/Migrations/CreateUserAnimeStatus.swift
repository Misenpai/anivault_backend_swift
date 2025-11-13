import Fluent
import FluentPostgresDriver

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
            .foreignKey("user_email", references: "users", "email", onDelete: .cascade)
            .create()
        
        // Create composite key, indexes, and constraints using PostgreSQL
        guard let postgres = database as? PostgresDatabase else {
            throw Abort(.internalServerError, reason: "Database is not PostgreSQL")
        }
        
        try await postgres.query("""
            ALTER TABLE user_anime_status 
            ADD PRIMARY KEY (user_email, mal_id)
        """).get()
        
        try await postgres.query("""
            CREATE INDEX idx_user_anime_status_user 
            ON user_anime_status(user_email)
        """).get()
        
        try await postgres.query("""
            CREATE INDEX idx_user_anime_status_mal_id 
            ON user_anime_status(mal_id)
        """).get()
        
        try await postgres.query("""
            CREATE INDEX idx_user_anime_status_watch_status 
            ON user_anime_status(watch_status)
        """).get()
        
        try await postgres.query("""
            CREATE INDEX idx_user_anime_status_anime_name 
            ON user_anime_status(anime_name)
        """).get()
        
        try await postgres.query("""
            CREATE INDEX idx_user_anime_status_updated 
            ON user_anime_status(last_updated_at DESC)
        """).get()
        
        // Add constraints
        try await postgres.query("""
            ALTER TABLE user_anime_status 
            ADD CONSTRAINT valid_watch_status 
            CHECK (watch_status IN ('Watching', 'Completed', 'PlanToWatch', 'Dropped', 'OnHold'))
        """).get()
        
        try await postgres.query("""
            ALTER TABLE user_anime_status 
            ADD CONSTRAINT valid_episodes_count 
            CHECK (episodes_watched >= 0 AND episodes_watched <= total_episodes)
        """).get()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("user_anime_status").delete()
    }
}