import Fluent

struct CreateEmailVerifications: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("email_verifications")
            .id()
            .field("email", .string, .required)
            .field("code", .string, .required)
            .field("expires_at", .datetime)
            .field("created_at", .datetime)
            .create()

        try await database.schema("email_verifications")
            .createIndex(on: "email")
            .createIndex(on: "code")
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("email_verifications").delete()
    }
}
