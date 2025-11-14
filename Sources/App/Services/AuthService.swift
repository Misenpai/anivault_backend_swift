import Fluent
import JWTKit
import Vapor

final class AuthService {
    private let userRepository: UserRepository
    private let jwtService: JWTService

    init(userRepository: UserRepository, jwtService: JWTService) {
        self.userRepository = userRepository
        self.jwtService = jwtService
    }

    private func generateUsername(from email: String) -> String {
        let components = email.components(separatedBy: "@")
        return components.first ?? "user"
    }

    private func isUsernameUnique(_ username: String, on db: Database) async throws -> Bool {
        let count = try await User.query(on: db)
            .filter(\.$username == username)
            .count()
        return count == 0
    }

    private func makeUsernameUnique(_ baseUsername: String, on db: Database) async throws -> String
    {
        var username = baseUsername
        var counter = 1

        while !(try await isUsernameUnique(username, on: db)) {
            username = "\(baseUsername)\(counter)"
            counter += 1
        }

        return username
    }

    func signup(email: String, password: String, on req: Request) async throws -> TokenResponse {
        let emailRegex = "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES[c] %@", emailRegex)
        guard emailPredicate.evaluate(with: email) else {
            throw Abort(.badRequest, reason: "Invalid email format")
        }

        if (try await userRepository.findByEmail(email, on: req.db)) != nil {
            throw Abort(.conflict, reason: "Email already exists")
        }

        let baseUsername = generateUsername(from: email)
        let uniqueUsername = try await makeUsernameUnique(baseUsername, on: req.db)

        let passwordHash = try Bcrypt.hash(password)

        let user = User(
            email: email, username: uniqueUsername, passwordHash: passwordHash, roleId: 2)
        try await userRepository.create(user, on: req.db)

        try await sendVerificationEmail(to: email, on: req)

        return try await generateToken(for: user, on: req)
    }

    func login(email: String, password: String, on req: Request) async throws -> TokenResponse {
        guard let user = try await userRepository.findByEmail(email, on: req.db) else {
            throw Abort(.unauthorized, reason: "Invalid credentials")
        }

        guard try user.verify(password: password) else {
            throw Abort(.unauthorized, reason: "Invalid credentials")
        }

        user.lastLogin = Date()
        try await user.save(on: req.db)

        return try await generateToken(for: user, on: req)
    }

    func sendVerificationEmail(to email: String, on req: Request) async throws {
        let code = String(format: "%06d", Int.random(in: 100000...999999))
        let expiresAt = Date().addingTimeInterval(600)

        let verification = EmailVerification(email: email, code: code, expiresAt: expiresAt)
        try await verification.save(on: req.db)

        req.logger.info("Verification code for \(email): \(code)")
    }

    func verifyEmail(email: String, code: String, on req: Request) async throws -> Bool {
        guard
            let verification = try await EmailVerification.query(on: req.db)
                .filter(\.$email == email)
                .filter(\.$code == code)
                .first()
        else {
            throw Abort(.badRequest, reason: "Invalid verification code")
        }

        guard let expiresAt = verification.expiresAt, expiresAt > Date() else {
            throw Abort(.badRequest, reason: "Verification code expired")
        }

        guard let user = try await userRepository.findByEmail(email, on: req.db) else {
            throw Abort(.notFound, reason: "User not found")
        }

        user.emailVerified = true
        try await user.save(on: req.db)

        try await verification.delete(on: req.db)

        return true
    }

    func updateUsername(email: String, newUsername: String, on req: Request) async throws -> UserDTO
    {
        guard let user = try await userRepository.findByEmail(email, on: req.db) else {
            throw Abort(.notFound, reason: "User not found")
        }

        let usernameRegex = "^[a-zA-Z0-9_]{3,20}$"
        let usernamePredicate = NSPredicate(format: "SELF MATCHES %@", usernameRegex)
        guard usernamePredicate.evaluate(with: newUsername) else {
            throw Abort(
                .badRequest,
                reason: "Username must be 3-20 characters (letters, numbers, underscore only)")
        }

        if !(try await isUsernameUnique(newUsername, on: req.db)) {
            throw Abort(.conflict, reason: "Username already taken")
        }

        user.username = newUsername
        try await user.save(on: req.db)

        return try await getUserDTO(user: user, on: req)
    }

    func generateToken(for user: User, on req: Request) async throws -> TokenResponse {
        if user.$role.value == nil {
            try await user.$role.load(on: req.db)
        }

        let token = try await jwtService.generateToken(for: user)
        let userDTO = try await getUserDTO(user: user, on: req)

        return TokenResponse(
            token: token,
            user: userDTO,
            expiresAt: Date().addingTimeInterval(3600 * 24 * 7)
        )
    }

    func getUserDTO(user: User, on req: Request) async throws -> UserDTO {
        return UserDTO(
            email: user.id!,
            username: user.username,
            roleId: user.roleId,
            emailVerified: user.emailVerified,
            createdAt: user.createdAt,
            lastLogin: user.lastLogin
        )
    }
}
