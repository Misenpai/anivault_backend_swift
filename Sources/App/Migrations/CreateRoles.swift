import Fluent

struct CreateRoles: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("roles")
            .id()
            .field("role_id", .int, .required)
            .field("role_title", .string, .required)
            .unique(on: "role_id")
            .unique(on: "role_title")
            .create()

        try await database.schema("roles")
            .createIndex(on: "role_id")
            .createIndex(on: "role_title")
            .update()

        try await seedRoles(on: database)
    }

    func revert(on database: Database) async throws {
        try await database.schema("roles").delete()
    }

    private func seedRoles(on database: Database) async throws {
        let roles = [
            Role(roleId: 1, roleTitle: "admin"),
            Role(roleId: 2, roleTitle: "user"),
            Role(roleId: 3, roleTitle: "moderator"),
            Role(roleId: 4, roleTitle: "guest"),
        ]

        for role in roles {
            try await role.save(on: database)
        }
    }
}
