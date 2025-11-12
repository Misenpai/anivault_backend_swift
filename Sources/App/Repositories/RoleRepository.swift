//
//  RoleRepository.swift
//  anivault_backend
//
//  Created by Sumit Sinha on 11/11/25.
//

import Fluent
import Vapor

final class RoleRepository {
    
    /// Find role by ID
    func findById(_ id: UUID, on db: Database) async throws -> Role? {
        return try await Role.find(id, on: db)
    }
    
    /// Find role by role_id (integer)
    func findByRoleId(_ roleId: Int, on db: Database) async throws -> Role? {
        return try await Role.query(on: db)
            .filter(\.$roleId == roleId)
            .first()
    }
    
    /// Find role by title
    func findByTitle(_ title: String, on db: Database) async throws -> Role? {
        return try await Role.query(on: db)
            .filter(\.$roleTitle == title)
            .first()
    }
    
    /// Create new role
    func create(_ role: Role, on db: Database) async throws {
        try await role.save(on: db)
    }
    
    /// Update role
    func update(_ role: Role, on db: Database) async throws {
        try await role.save(on: db)
    }
    
    /// Delete role
    func delete(_ role: Role, on db: Database) async throws {
        try await role.delete(on: db)
    }
    
    /// Get all roles
    func all(on db: Database) async throws -> [Role] {
        return try await Role.query(on: db)
            .sort(\.$roleId, .ascending)
            .all()
    }
    
    /// Check if role exists by roleId
    func exists(_ roleId: Int, on db: Database) async throws -> Bool {
        let count = try await Role.query(on: db)
            .filter(\.$roleId == roleId)
            .count()
        return count > 0
    }
    
    /// Check if role title exists
    func titleExists(_ title: String, on db: Database) async throws -> Bool {
        let count = try await Role.query(on: db)
            .filter(\.$roleTitle == title)
            .count()
        return count > 0
    }
    
    /// Get role with users
    func findByIdWithUsers(_ id: UUID, on db: Database) async throws -> Role? {
        return try await Role.query(on: db)
            .filter(\.$id == id)
            .with(\.$users)
            .first()
    }
    
    /// Count users in role
    func countUsers(_ roleId: Int, on db: Database) async throws -> Int {
        guard let role = try await findByRoleId(roleId, on: db) else {
            return 0
        }
        return try await role.$users.query(on: db).count()
    }
    
    /// Get default user role (role_id = 2)
    func getDefaultUserRole(on db: Database) async throws -> Role? {
        return try await findByRoleId(2, on: db)
    }
    
    /// Get admin role (role_id = 1)
    func getAdminRole(on db: Database) async throws -> Role? {
        return try await findByRoleId(1, on: db)
    }
}
