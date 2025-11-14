import Fluent
import FluentPostgresDriver
import Vapor

struct CreateUsers: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("users")
            .field("email", .string, .identifier(auto: false))
            .field("username", .string, .required)
            .field("password_hash", .string, .required)
            .field("role_id", .int, .required)
            .field("email_verified", .bool, .required)
            .field("created_at", .datetime)
            .field("last_login", .datetime)
            .unique(on: "email")
            .unique(on: "username")
            .foreignKey("role_id", references: "roles", "role_id", onDelete: .restrict)
            .create()

        guard let postgres = database as? any PostgresDatabase else {
            throw Abort(.internalServerError, reason: "Database is not PostgreSQL")
        }

        _ = try await postgres.query("CREATE INDEX idx_users_role ON users(role_id)").get()
        _ = try await postgres.query("CREATE INDEX idx_users_created_at ON users(created_at)").get()
        _ = try await postgres.query("CREATE INDEX idx_users_username ON users(username)").get()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("users").delete()
    }
}
