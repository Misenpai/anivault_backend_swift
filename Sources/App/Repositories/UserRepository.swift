//
//  UserRepository.swift
//  anivault_backend
//
//  Created by Sumit Sinha on 11/11/25.
//

import Fluent
import Vapor

final class UserRepository {
    
    /// Find user by email
    func findByEmail(_ email: String, on db: Database) async throws -> User? {
        return try await User.find(email, on: db)
    }
    
    /// Find user by username
    func findByUsername(_ username: String, on db: Database) async throws -> User? {
        return try await User.query(on: db)
            .filter(\.$username == username)
            .first()
    }
    
    /// Create new user
    func create(_ user: User, on db: Database) async throws {
        try await user.save(on: db)
    }
    
    /// Update user
    func update(_ user: User, on db: Database) async throws {
        try await user.save(on: db)
    }
    
    /// Delete user
    func delete(_ user: User, on db: Database) async throws {
        try await user.delete(on: db)
    }
    
    /// Get all users
    func all(on db: Database) async throws -> [User] {
        return try await User.query(on: db).all()
    }
    
    /// Get users with pagination
    func paginated(page: Int, limit: Int, on db: Database) async throws -> Page<User> {
        return try await User.query(on: db)
            .paginate(PageRequest(page: page, per: limit))
    }
    
    /// Check if email exists
    func emailExists(_ email: String, on db: Database) async throws -> Bool {
        let count = try await User.query(on: db)
            .filter(\.$id == email)
            .count()
        return count > 0
    }
    
    /// Check if username exists
    func usernameExists(_ username: String, on db: Database) async throws -> Bool {
        let count = try await User.query(on: db)
            .filter(\.$username == username)
            .count()
        return count > 0
    }
    
    /// Find users by role
    func findByRole(_ roleId: Int, on db: Database) async throws -> [User] {
        return try await User.query(on: db)
            .filter(\.$roleId == roleId)
            .all()
    }
    
    /// Get user with role loaded
    func findByEmailWithRole(_ email: String, on db: Database) async throws -> User? {
        return try await User.query(on: db)
            .filter(\.$id == email)
            .with(\.$role)
            .first()
    }
    
    /// Update last login
    func updateLastLogin(_ user: User, on db: Database) async throws {
        user.lastLogin = Date()
        try await user.save(on: db)
    }
    
    /// Search users by username (partial match)
    func searchByUsername(_ query: String, limit: Int, on db: Database) async throws -> [User] {
        return try await User.query(on: db)
            .filter(\.$username =~ query) // Case-insensitive LIKE
            .limit(limit)
            .all()
    }
    
    /// Get recently registered users
    func recentlyRegistered(limit: Int, on db: Database) async throws -> [User] {
        return try await User.query(on: db)
            .sort(\.$createdAt, .descending)
            .limit(limit)
            .all()
    }
    
    /// Count total users
    func count(on db: Database) async throws -> Int {
        return try await User.query(on: db).count()
    }
    
    /// Count verified users
    func countVerified(on db: Database) async throws -> Int {
        return try await User.query(on: db)
            .filter(\.$emailVerified == true)
            .count()
    }
    
    /// Get users by IDs
    func findByEmails(_ emails: [String], on db: Database) async throws -> [User] {
        return try await User.query(on: db)
            .filter(\.$id ~~ emails)
            .all()
    }
}
