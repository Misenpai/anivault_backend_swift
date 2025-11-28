import Fluent
import JWTKit
import Vapor

struct AuthController: RouteCollection {
    private let authService: AuthService

    init(authService: AuthService) {
        self.authService = authService
    }

    func boot(routes: any RoutesBuilder) throws {
        let auth = routes.grouped("auth")

        // Public routes
        auth.post("signup", use: signup)
        auth.post("login", use: login)
        auth.post("refresh", use: refreshToken)
        auth.post("verify-email", use: sendVerificationCode)
        auth.post("verify-code", use: verifyCode)

        // Protected routes
        let protected = auth.grouped(JWTAuthenticationMiddleware())
        protected.get("me", use: getCurrentUser)
        protected.put("username", use: updateUsername)
        protected.post("logout", use: logout)
    }

    private func signup(req: Request) async throws -> TokenResponse {
        try SignupRequest.validate(content: req)
        let signupRequest = try req.content.decode(SignupRequest.self)

        return try await authService.signup(
            email: signupRequest.email,
            password: signupRequest.password,
            on: req.db,
            logger: req.logger
        )
    }

    private func login(req: Request) async throws -> TokenResponse {
        try LoginRequest.validate(content: req)
        let loginRequest = try req.content.decode(LoginRequest.self)

        return try await authService.login(
            identifier: loginRequest.identifier,
            password: loginRequest.password,
            on: req.db
        )
    }

    private func refreshToken(req: Request) async throws -> RefreshTokenResponse {
        let request = try req.content.decode(RefreshTokenRequest.self)
        return try await authService.refreshAccessToken(
            refreshToken: request.refreshToken,
            on: req.db
        )
    }

    private func logout(req: Request) async throws -> HTTPStatus {
        let request = try req.content.decode(LogoutRequest.self)
        try await authService.logout(refreshToken: request.refreshToken, on: req.db)
        return .ok
    }

    private func sendVerificationCode(req: Request) async throws -> HTTPStatus {
        let request = try req.content.decode(VerifyEmailRequest.self)
        try await authService.sendVerificationEmail(
            to: request.email, on: req.db, logger: req.logger)
        return .ok
    }

    private func verifyCode(req: Request) async throws -> HTTPStatus {
        let request = try req.content.decode(VerifyCodeRequest.self)
        let verified = try await authService.verifyEmail(
            email: request.email,
            code: request.code,
            on: req.db
        )
        return verified ? .ok : .badRequest
    }

    private func updateUsername(req: Request) async throws -> UserDTO {
        let user = try req.auth.require(User.self)
        let request = try req.content.decode(UpdateUsernameRequest.self)

        return try await authService.updateUsername(
            email: user.id!,
            newUsername: request.username,
            on: req.db
        )
    }

    private func getCurrentUser(req: Request) async throws -> UserDTO {
        let user = try req.auth.require(User.self)
        return try await authService.getUserDTO(user: user)
    }
}
