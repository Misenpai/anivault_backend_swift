import Fluent
import FluentPostgresDriver
import Vapor

struct CreateEndpointRoleAccess: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("endpoint_role_access")
            .field("endpoint", .string, .required)
            .field("method", .string, .required)
            .field("role_id", .int, .required)
            .field("granted_at", .datetime)
            .foreignKey("role_id", references: "roles", "role_id", onDelete: .cascade)
            .create()
        
        // Create composite key and indexes using PostgreSQL
        guard let postgres = database as? any PostgresDatabase else {
            throw Abort(.internalServerError, reason: "Database is not PostgreSQL")
        }
        
        try await postgres.query("""
            ALTER TABLE endpoint_role_access 
            ADD PRIMARY KEY (endpoint, method, role_id)
        """).get()
        
        try await postgres.query("""
            ALTER TABLE endpoint_role_access 
            ADD FOREIGN KEY (endpoint, method) 
            REFERENCES endpoints(endpoint, method) 
            ON DELETE CASCADE
        """).get()
        
        try await postgres.query("""
            CREATE INDEX idx_endpoint_role_access_role 
            ON endpoint_role_access(role_id)
        """).get()
        
        try await postgres.query("""
            CREATE INDEX idx_endpoint_role_access_endpoint_method 
            ON endpoint_role_access(endpoint, method)
        """).get()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema("endpoint_role_access").delete()
    }
}