import Fluent

struct AddAttemptsToEmailVerifications: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("email_verifications")
            .field("attempts", .int, .required, .sql(.default(0)))
            .field("last_attempt_at", .datetime)
            .update()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("email_verifications")
            .deleteField("attempts")
            .deleteField("last_attempt_at")
            .update()
    }
}
