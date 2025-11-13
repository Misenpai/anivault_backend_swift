import Fluent
import Vapor

final class RoleRepository {
    
    func findById(_ id: Int, on db: Database) async throws -> Role? {
        // ✅ FIX: Use correct filter syntax
        return try await Role.query(on: db)
            .filter(\.$id == id)
            .first()
    }
    
    func findByTitle(_ title: String, on db: Database) async throws -> Role? {
        return try await Role.query(on: db)
            .filter(\.$roleTitle == title)
            .first()
    }
    
    func all(on db: Database) async throws -> [Role] {
        return try await Role.query(on: db)
            .sort(\.$id, .ascending)
            .all()
    }
    
    func exists(_ roleId: Int, on db: Database) async throws -> Bool {
        let count = try await Role.query(on: db)
            .filter(\.$id == roleId)
            .count()
        return count > 0
    }
    
    func titleExists(_ title: String, on db: Database) async throws -> Bool {
        let count = try await Role.query(on: db)
            .filter(\.$roleTitle == title)
            .count()
        return count > 0
    }
    
    func findByIdWithUsers(_ id: Int, on db: Database) async throws -> Role? {
        return try await Role.query(on: db)
            .filter(\.$id == id)
            .with(\.$users)
            .first()
    }
    
    func countUsers(_ roleId: Int, on db: Database) async throws -> Int {
        guard let role = try await findById(roleId, on: db) else {
            return 0
        }
        return try await role.$users.query(on: db).count()
    }
    
    func getDefaultUserRole(on db: Database) async throws -> Role? {
        return try await findById(2, on: db)
    }
    
    func getAdminRole(on db: Database) async throws -> Role? {
        return try await findById(1, on: db)
    }
}