//
//  AuthController.swift
//  anivault_backend
//
//  Created by Sumit Sinha on 09/11/25.
//

import Vapor
import JWTKit
import Fluent

final class AuthController: RouteCollection {
    private let authService: AuthService
    
    init(authService: AuthService) {
        self.authService = authService
    }
    
    func boot(routes: any RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        
        // Public routes
        auth.post("signup", use: signup)
        auth.post("login", use: login)
        auth.post("verify-email", use: sendVerificationCode)
        auth.post("verify-code", use: verifyCode)
        
        // Protected routes
        let protected = auth.grouped(JWTAuthenticationMiddleware())
        protected.get("me", use: getCurrentUser)
        protected.put("username", use: updateUsername)
        protected.post("refresh", use: refreshToken)
    }
    
    private func signup(req: Request) async throws -> TokenResponse {
        try SignupRequest.validate(content: req)
        let signupRequest = try req.content.decode(SignupRequest.self)
        
        return try await authService.signup(
            email: signupRequest.email,
            password: signupRequest.password,
            on: req
        )
    }
    
    private func login(req: Request) async throws -> TokenResponse {
        try LoginRequest.validate(content: req)
        let loginRequest = try req.content.decode(LoginRequest.self)
        
        return try await authService.login(
            email: loginRequest.email,
            password: loginRequest.password,
            on: req
        )
    }
    
    private func sendVerificationCode(req: Request) async throws -> HTTPStatus {
        let request = try req.content.decode(VerifyEmailRequest.self)
        try await authService.sendVerificationEmail(to: request.email, on: req)
        return .ok
    }
    
    private func verifyCode(req: Request) async throws -> HTTPStatus {
        let request = try req.content.decode(VerifyCodeRequest.self)
        let verified = try await authService.verifyEmail(
            email: request.email,
            code: request.code,
            on: req
        )
        return verified ? .ok : .badRequest
    }
    
    private func updateUsername(req: Request) async throws -> UserDTO {
        let user = try req.auth.require(User.self)
        let request = try req.content.decode(UpdateUsernameRequest.self)
        
        return try await authService.updateUsername(
            email: user.id!,
            newUsername: request.username,
            on: req
        )
    }
    
    private func getCurrentUser(req: Request) async throws -> UserDTO {
        let user = try req.auth.require(User.self)
        return try await authService.getUserDTO(user: user, on: req)
    }
    
    private func refreshToken(req: Request) async throws -> TokenResponse {
        let user = try req.auth.require(User.self)
        return try await authService.generateToken(for: user, on: req)
    }
}
