import Fluent
import Vapor

final class UserRepository {

    func findByEmail(_ email: String, on db: any Database) async throws -> User? {
        return try await User.find(email, on: db)
    }

    func findByUsername(_ username: String, on db: any Database) async throws -> User? {
        return try await User.query(on: db)
            .filter(\.$username == username)
            .first()
    }

    func create(_ user: User, on db: any Database) async throws {
        try await user.save(on: db)
    }

    func update(_ user: User, on db: any Database) async throws {
        try await user.save(on: db)
    }

    func delete(_ user: User, on db: any Database) async throws {
        try await user.delete(on: db)
    }

    func all(on db: any Database) async throws -> [User] {
        return try await User.query(on: db).all()
    }

    func paginated(page: Int, limit: Int, on db: any Database) async throws -> Page<User> {
        return try await User.query(on: db)
            .paginate(PageRequest(page: page, per: limit))
    }

    func emailExists(_ email: String, on db: any Database) async throws -> Bool {
        let count = try await User.query(on: db)
            .filter(\.$id == email)
            .count()
        return count > 0
    }

    func usernameExists(_ username: String, on db: any Database) async throws -> Bool {
        let count = try await User.query(on: db)
            .filter(\.$username == username)
            .count()
        return count > 0
    }

    func findByRole(_ roleId: Int, on db: any Database) async throws -> [User] {
        return try await User.query(on: db)
            .filter(\.$role.$id == roleId)
            .all()
    }

    func findByEmailWithRole(_ email: String, on db: any Database) async throws -> User? {
        return try await User.query(on: db)
            .filter(\.$id == email)
            .with(\.$role)
            .first()
    }

    func updateLastLogin(_ user: User, on db: any Database) async throws {
        user.lastLogin = Date()
        try await user.save(on: db)
    }

    func searchByUsername(_ query: String, limit: Int, on db: any Database) async throws -> [User] {
        return try await User.query(on: db)
            .filter(\.$username =~ query)
            .limit(limit)
            .all()
    }

    func recentlyRegistered(limit: Int, on db: any Database) async throws -> [User] {
        return try await User.query(on: db)
            .sort(\.$createdAt, .descending)
            .limit(limit)
            .all()
    }

    func count(on db: any Database) async throws -> Int {
        return try await User.query(on: db).count()
    }

    func countVerified(on db: any Database) async throws -> Int {
        return try await User.query(on: db)
            .filter(\.$emailVerified == true)
            .count()
    }

    func findByEmails(_ emails: [String], on db: any Database) async throws -> [User] {
        return try await User.query(on: db)
            .filter(\.$id ~~ emails)
            .all()
    }
}
