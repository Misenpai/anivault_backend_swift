import Vapor
import Fluent

struct UserService {
    private let userRepository: UserRepository

    init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }

    func getAllUsers(on req: Request) async throws -> [UserDTO] {
        let users = try await userRepository.all(on: req.db)
        return users.map { $0.toDTO() }
    }

    func getUser(email: String, on req: Request) async throws -> UserDTO {
        guard let user = try await userRepository.findByEmail(email, on: req.db) else {
            throw Abort(.notFound)
        }
        return user.toDTO()
    }

    func updateUser(email: String, data: UserPatchRequest, on req: Request) async throws -> UserDTO {
        guard let user = try await userRepository.findByEmail(email, on: req.db) else {
            throw Abort(.notFound)
        }

        user.username = data.username ?? user.username
        
        try await userRepository.update(user, on: req.db)
        return user.toDTO()
    }

    func patchUser(email: String, data: [String: String], on req: Request) async throws -> UserDTO {
        guard let user = try await userRepository.findByEmail(email, on: req.db) else {
            throw Abort(.notFound)
        }

        if let username = data["username"] {
            user.username = username
        }
        if let profileImage = data["profileImage"] {
            user.profileImage = profileImage
        }
        if let bio = data["bio"] {
            user.bio = bio
        }

        try await userRepository.update(user, on: req.db)
        return user.toDTO()
    }

    func deleteUser(email: String, on req: Request) async throws {
        guard let user = try await userRepository.findByEmail(email, on: req.db) else {
            throw Abort(.notFound)
        }
        try await userRepository.delete(user, on: req.db)
    }

    func getUsersPaginated(page: Int, limit: Int, on req: Request) async throws -> Page<UserDTO> {
        let users = try await userRepository.paginated(page: page, limit: limit, on: req.db)
        return users.map { $0.toDTO() }
    }
}
