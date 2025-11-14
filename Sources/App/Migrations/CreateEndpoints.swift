import Fluent
import FluentPostgresDriver
import Vapor
struct CreateEndpoints: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("endpoints")
            .field("endpoint", .string, .required)
            .field("method", .string, .required)
            .field("description", .string)
            .field("created_at", .datetime)
            .create()
        
        // Create composite primary key and indexes using PostgreSQL
        guard let postgres = database as? any PostgresDatabase else {
            throw Abort(.internalServerError, reason: "Database is not PostgreSQL")
        }
        
        try await postgres.query("ALTER TABLE endpoints ADD PRIMARY KEY (endpoint, method)").get()
        try await postgres.query("CREATE INDEX idx_endpoints_endpoint ON endpoints(endpoint)").get()
        try await postgres.query("CREATE INDEX idx_endpoints_method ON endpoints(method)").get()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema("endpoints").delete()
    }
}