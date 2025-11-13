import Fluent
import FluentPostgresDriver

struct CreateRoles: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("roles")
            .field("role_id", .int, .identifier(auto: true))
            .field("role_title", .string, .required)
            .unique(on: "role_id")
            .unique(on: "role_title")
            .create()
        
        // Create indexes using PostgreSQL
        guard let postgres = database as? PostgresDatabase else {
            throw Abort(.internalServerError, reason: "Database is not PostgreSQL")
        }
        
        try await postgres.query("CREATE INDEX idx_roles_role_id ON roles(role_id)").get()
        try await postgres.query("CREATE INDEX idx_roles_title ON roles(role_title)").get()
        
        try await seedRoles(on: database)
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("roles").delete()
    }
    
    private func seedRoles(on database: Database) async throws {
        let roles = [
            Role(id: 1, roleTitle: "admin"),
            Role(id: 2, roleTitle: "user"),
            Role(id: 3, roleTitle: "moderator"),
            Role(id: 4, roleTitle: "guest"),
        ]
        
        for role in roles {
            try await role.save(on: database)
        }
    }
}