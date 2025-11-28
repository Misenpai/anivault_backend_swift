import Fluent
import JWTKit
import Vapor

final actor AuthService {
    private let userRepository: UserRepository
    private let jwtService: JWTService
    private let emailService: SMTPEmailService?

    private let accessTokenExpiration: TimeInterval = 3600
    private let refreshTokenExpiration: TimeInterval = 2_592_000

    init(userRepository: UserRepository, jwtService: JWTService, emailService: SMTPEmailService?) {
        self.userRepository = userRepository
        self.jwtService = jwtService
        self.emailService = emailService
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

    func signup(email: String, password: String, on db: any Database, logger: Logger? = nil)
        async throws -> TokenResponse
    {
        let emailRegex = "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES[c] %@", emailRegex)
        guard emailPredicate.evaluate(with: email) else {
            throw Abort(.badRequest, reason: "Invalid email format")
        }

        if (try await userRepository.findByEmail(email, on: db)) != nil {
            throw Abort(.conflict, reason: "Email already exists")
        }

        let baseUsername = generateUsername(from: email)
        let uniqueUsername = try await makeUsernameUnique(baseUsername, on: db)

        let passwordHash = try Bcrypt.hash(password)

        let user = User(
            email: email, username: uniqueUsername, passwordHash: passwordHash, roleId: 2)
        try await userRepository.create(user, on: db)

        try await sendVerificationEmail(to: email, on: db, logger: logger)

        return try await generateTokenPair(for: user, on: db)
    }

    func login(identifier: String, password: String, on db: any Database) async throws
        -> TokenResponse
    {
        var user: User?

        if identifier.contains("@") {
            user = try await userRepository.findByEmail(identifier, on: db)
        } else {
            user = try await userRepository.findByUsername(identifier, on: db)
        }

        guard let foundUser = user else {
            throw Abort(.unauthorized, reason: "Invalid credentials")
        }

        guard try foundUser.verify(password: password) else {
            throw Abort(.unauthorized, reason: "Invalid credentials")
        }

        guard foundUser.emailVerified else {
            throw Abort(.forbidden, reason: "Email not verified")
        }

        foundUser.lastLogin = Date()
        try await foundUser.save(on: db)

        return try await generateTokenPair(for: foundUser, on: db)
    }

    func refreshAccessToken(refreshToken: String, on db: any Database) async throws
        -> RefreshTokenResponse
    {
        guard
            let storedToken = try await RefreshToken.query(on: db)
                .filter(\.$token == refreshToken)
                .filter(\.$isRevoked == false)
                .first()
        else {
            throw Abort(.unauthorized, reason: "Invalid refresh token")
        }

        if let expiresAt = storedToken.expiresAt, expiresAt < Date() {
            throw Abort(.unauthorized, reason: "Refresh token expired")
        }

        guard let user = try await userRepository.findByEmail(storedToken.userEmail, on: db)
        else {
            throw Abort(.unauthorized, reason: "User not found")
        }

        let newAccessToken = try await jwtService.generateToken(
            for: user, expiration: accessTokenExpiration)

        storedToken.isRevoked = true
        try await storedToken.save(on: db)

        let newRefreshToken = try await createRefreshToken(for: user, on: db)

        return RefreshTokenResponse(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken.token,
            expiresAt: Date().addingTimeInterval(accessTokenExpiration)
        )
    }

    func logout(refreshToken: String, on db: any Database) async throws {
        if let token = try await RefreshToken.query(on: db)
            .filter(\.$token == refreshToken)
            .first()
        {
            token.isRevoked = true
            try await token.save(on: db)
        }
    }

    private func generateTokenPair(for user: User, on db: any Database) async throws
        -> TokenResponse
    {
        if user.$role.value == nil {
            try await user.$role.load(on: db)
        }

        let accessToken = try await jwtService.generateToken(
            for: user, expiration: accessTokenExpiration)
        let refreshToken = try await createRefreshToken(for: user, on: db)
        let userDTO = try await getUserDTO(user: user)

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

    func sendVerificationEmail(to email: String, on db: any Database, logger: Logger? = nil)
        async throws
    {
        let code = String(format: "%06d", Int.random(in: 100000...999999))
        let expiresAt = Date().addingTimeInterval(Constants.Email.Verification.codeExpiration)

        // Check for existing verification
        if let existingVerification = try await EmailVerification.query(on: db)
            .filter(\.$email == email)
            .first()
        {
            // Check cooldown
            if let lastAttempt = existingVerification.lastAttemptAt,
                Date().timeIntervalSince(lastAttempt) < Constants.Email.Verification.resendCooldown
            {
                throw Abort(
                    .tooManyRequests,
                    reason: "Please wait before requesting another code")
            }

            // Check max attempts
            if existingVerification.attempts >= Constants.Email.Verification.maxResendAttempts {
                if let oldExpiresAt = existingVerification.expiresAt, oldExpiresAt < Date() {
                    existingVerification.attempts = 0
                } else {
                    throw Abort(
                        .tooManyRequests,
                        reason: "Maximum resend attempts reached. Please try again later.")
                }
            }

            existingVerification.code = code
            existingVerification.expiresAt = expiresAt
            existingVerification.attempts += 1
            existingVerification.lastAttemptAt = Date()
            try await existingVerification.save(on: db)
        } else {
            let verification = EmailVerification(email: email, code: code, expiresAt: expiresAt)
            verification.attempts = 1
            verification.lastAttemptAt = Date()
            try await verification.save(on: db)
        }

        if let emailService = self.emailService {
            do {
                try await emailService.sendOTPEmail(to: email, otp: code, on: db.eventLoop)
                logger?.info("Verification email sent to \(email)")
            } catch {
                logger?.error("Failed to send email: \(error)")
                throw Abort(.internalServerError, reason: "Failed to send verification email")
            }
        } else {
            logger?.warning(
                "EmailService not configured. Verification code for \(email): \(code)")
        }
    }

    func verifyEmail(email: String, code: String, on db: any Database) async throws -> Bool {
        guard
            let verification = try await EmailVerification.query(on: db)
                .filter(\.$email == email)
                .filter(\.$code == code)
                .first()
        else {
            throw Abort(.badRequest, reason: "Invalid verification code")
        }

        guard let expiresAt = verification.expiresAt, expiresAt > Date() else {
            throw Abort(.badRequest, reason: "Verification code expired")
        }

        guard let user = try await userRepository.findByEmail(email, on: db) else {
            throw Abort(.notFound, reason: "User not found")
        }

        user.emailVerified = true
        try await user.save(on: db)

        try await verification.delete(on: db)

        return true
    }

    func updateUsername(email: String, newUsername: String, on db: any Database) async throws
        -> UserDTO
    {
        guard let user = try await userRepository.findByEmail(email, on: db) else {
            throw Abort(.notFound, reason: "User not found")
        }

        let usernameRegex = "^[a-zA-Z0-9_]{3,20}$"
        let usernamePredicate = NSPredicate(format: "SELF MATCHES %@", usernameRegex)
        guard usernamePredicate.evaluate(with: newUsername) else {
            throw Abort(
                .badRequest,
                reason: "Username must be 3-20 characters (letters, numbers, underscore only)")
        }

        if !(try await isUsernameUnique(newUsername, on: db)) {
            throw Abort(.conflict, reason: "Username already taken")
        }

        user.username = newUsername
        try await user.save(on: db)

        return try await getUserDTO(user: user)
    }

    func getUserDTO(user: User) async throws -> UserDTO {
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
