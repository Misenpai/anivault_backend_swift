import Fluent

struct CreateEndpoints: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("endpoints")
            .field("endpoint", .string, .required)
            .field("method", .string, .required)
            .field("description", .string)
            .field("created_at", .datetime)
            .compositePrimaryKey(on: "endpoint", "method")
            .create()

        try await database.schema("endpoints")
            .createIndex(on: "endpoint")
            .createIndex(on: "method")
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("endpoints").delete()
    }
}
