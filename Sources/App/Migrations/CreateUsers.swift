import Fluent

struct CreateUsers: AsyncMigration {
    func prepare(on database: Database) async throws {
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

        try await database.schema("users")
            .createIndex(on: "role_id")
            .createIndex(on: "username")
            .createIndex(on: "email_verified")
            .createIndex(on: "created_at")
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users").delete()
    }
}
