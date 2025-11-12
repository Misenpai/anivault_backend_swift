import Fluent

struct CreateEndpointRoleAccess: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("endpoint_role_access")
            .field("endpoint", .string, .required)
            .field("method", .string, .required)
            .field("role_id", .int, .required)
            .field("granted_at", .datetime)
            .compositePrimaryKey(on: "endpoint", "method", "role_id")
            .foreignKey("role_id", references: "roles", "role_id", onDelete: .cascade)
            .create()

        try await database.schema("endpoint_role_access")
            .createIndex(on: "role_id")
            .createIndex(on: "endpoint", "method")
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("endpoint_role_access").delete()
    }
}
