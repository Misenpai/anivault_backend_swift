import Fluent
import JWTKit
import Vapor

final class AuthService {
    private let userRepository: UserRepository
    private let jwtService: JWTService

    private let accessTokenExpiration: TimeInterval = 3600
    private let refreshTokenExpiration: TimeInterval = 2_592_000

    init(userRepository: UserRepository, jwtService: JWTService) {
        self.userRepository = userRepository
        self.jwtService = jwtService
    }

    private func generateUsername(from email: String) -> String {
        let components = email.components(separatedBy: "@")
        return components.first ?? "user"
    }

    private func isUsernameUnique(_ username: String, on db: any Database) async throws -> Bool {
        let count = try await User.query(on: db)
            .filter(\.$username == username)
            .count()
        return count == 0
    }

    private func makeUsernameUnique(_ baseUsername: String, on db: any Database) async throws
        -> String
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

        return try await generateTokenPair(for: user, on: req)
    }

    func login(identifier: String, password: String, on req: Request) async throws -> TokenResponse
    {

        var user: User?

        if identifier.contains("@") {

            user = try await userRepository.findByEmail(identifier, on: req.db)
        } else {

            user = try await userRepository.findByUsername(identifier, on: req.db)
        }

        guard let foundUser = user else {
            throw Abort(.unauthorized, reason: "Invalid credentials")
        }

        guard try foundUser.verify(password: password) else {
            throw Abort(.unauthorized, reason: "Invalid credentials")
        }

        foundUser.lastLogin = Date()
        try await foundUser.save(on: req.db)

        return try await generateTokenPair(for: foundUser, on: req)
    }

    func refreshAccessToken(refreshToken: String, on req: Request) async throws
        -> RefreshTokenResponse
    {

        guard
            let storedToken = try await RefreshToken.query(on: req.db)
                .filter(\.$token == refreshToken)
                .filter(\.$isRevoked == false)
                .first()
        else {
            throw Abort(.unauthorized, reason: "Invalid refresh token")
        }

        if let expiresAt = storedToken.expiresAt, expiresAt < Date() {
            throw Abort(.unauthorized, reason: "Refresh token expired")
        }

        guard let user = try await userRepository.findByEmail(storedToken.userEmail, on: req.db)
        else {
            throw Abort(.unauthorized, reason: "User not found")
        }

        let newAccessToken = try await jwtService.generateToken(
            for: user, expiration: accessTokenExpiration)

        storedToken.isRevoked = true
        try await storedToken.save(on: req.db)

        let newRefreshToken = try await createRefreshToken(for: user, on: req.db)

        return RefreshTokenResponse(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken.token,
            expiresAt: Date().addingTimeInterval(accessTokenExpiration)
        )
    }

    func logout(refreshToken: String, on req: Request) async throws {

        if let token = try await RefreshToken.query(on: req.db)
            .filter(\.$token == refreshToken)
            .first()
        {
            token.isRevoked = true
            try await token.save(on: req.db)
        }
    }

    private func generateTokenPair(for user: User, on req: Request) async throws -> TokenResponse {
        if user.$role.value == nil {
            try await user.$role.load(on: req.db)
        }

        let accessToken = try await jwtService.generateToken(
            for: user, expiration: accessTokenExpiration)
        let refreshToken = try await createRefreshToken(for: user, on: req.db)
        let userDTO = try await getUserDTO(user: user, on: req)

        return TokenResponse(
            accessToken: accessToken,
            refreshToken: refreshToken.token,
            user: userDTO,
            expiresAt: Date().addingTimeInterval(accessTokenExpiration)
        )
    }

    private func createRefreshToken(for user: User, on db: any Database) async throws
        -> RefreshToken
    {
        let tokenString = [UInt8].random(count: 32).base64String()
        let expiresAt = Date().addingTimeInterval(refreshTokenExpiration)

        let refreshToken = RefreshToken(
            token: tokenString,
            userEmail: user.id!,
            expiresAt: expiresAt
        )

        try await refreshToken.save(on: db)
        return refreshToken
    }

    func sendVerificationEmail(to email: String, on req: Request) async throws {
        let code = String(format: "%06d", Int.random(in: 100000...999999))
        let expiresAt = Date().addingTimeInterval(600)

        let verification = EmailVerification(email: email, code: code, expiresAt: expiresAt)
        try await verification.save(on: req.db)

        // ✅ Fixed: Add the 'otp: code' parameter
        if let emailService = req.application.storage[ResendEmailServiceKey.self] {
            do {
                try await emailService.sendOTPEmail(to: email, otp: code, client: req.client)
                req.logger.info("📧 Verification email sent to \(email)")
            } catch {
                req.logger.error("❌ Failed to send email: \(error)")
                throw Abort(.internalServerError, reason: "Failed to send verification email")
            }
        } else {
            req.logger.warning(
                "⚠️ EmailService not configured. Verification code for \(email): \(code)")
        }
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

extension Array where Element == UInt8 {
    static func random(count: Int) -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: count)
        _ = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
        return bytes
    }

    func base64String() -> String {
        return Data(self).base64EncodedString()
    }
}
