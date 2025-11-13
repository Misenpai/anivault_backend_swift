import Fluent
import FluentPostgresDriver

struct CreateEmailVerifications: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("email_verifications")
            .id()
            .field("email", .string, .required)
            .field("code", .string, .required)
            .field("expires_at", .datetime)
            .field("created_at", .datetime)
            .create()
        
        // Create indexes using PostgreSQL
        guard let postgres = database as? PostgresDatabase else {
            throw Abort(.internalServerError, reason: "Database is not PostgreSQL")
        }
        
        try await postgres.query("""
            CREATE INDEX idx_email_verifications_email 
            ON email_verifications(email)
        """).get()
        
        try await postgres.query("""
            CREATE INDEX idx_email_verifications_code 
            ON email_verifications(code)
        """).get()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("email_verifications").delete()
    }
}