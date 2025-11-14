import Fluent
import FluentPostgresDriver
import Vapor

struct CreateRefreshTokens: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("refresh_tokens")
            .id()
            .field("token", .string, .required)
            .field("user_email", .string, .required)
            .field("expires_at", .datetime, .required)
            .field("created_at", .datetime)
            .field("is_revoked", .bool, .required)
            .unique(on: "token")
            .foreignKey("user_email", references: "users", "email", onDelete: .cascade)
            .create()

        guard let postgres = database as? any PostgresDatabase else {
            throw Abort(.internalServerError, reason: "Database is not PostgreSQL")
        }

        _ = try await postgres.query(
            """
                CREATE INDEX idx_refresh_tokens_user ON refresh_tokens(user_email)
            """
        ).get()

        _ = try await postgres.query(
            """
                CREATE INDEX idx_refresh_tokens_token ON refresh_tokens(token)
            """
        ).get()

        _ = try await postgres.query(
            """
                CREATE INDEX idx_refresh_tokens_expires ON refresh_tokens(expires_at)
            """
        ).get()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("refresh_tokens").delete()
    }
}
