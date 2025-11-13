//
//  ProfileController.swift
//  anivault_backend
//
//  Created by Sumit Sinha on 09/11/25.
//

import Vapor
import Fluent

final class ProfileController: RouteCollection {
    private let profileService: ProfileService
    
    init(profileService: ProfileService) {
        self.profileService = profileService
    }
    
    func boot(routes: any RoutesBuilder) throws {
        let profile = routes.grouped("profile")
        
        // Public profile (can be viewed without auth)
        profile.get(":username", use: getPublicProfile)
        
        // Protected routes
        let protected = profile.grouped(JWTAuthenticationMiddleware())
        protected.get("me", "stats", use: getMyStats)
    }
    
    private func getPublicProfile(req: Request) async throws -> PublicProfileDTO {
        guard let username = req.parameters.get("username") else {
            throw Abort(.badRequest, reason: "Username required")
        }
        
        // Get viewer email if authenticated
        let viewerEmail = try? req.auth.require(User.self).id
        
        return try await profileService.getPublicProfile(
            username: username,
            viewerEmail: viewerEmail,
            on: req.db
        )
    }
    
    private func getMyStats(req: Request) async throws -> AnimeStatsDTO {
        let user = try req.auth.require(User.self)
        return try await profileService.getAnimeStats(userEmail: user.id!, on: req.db)
    }
}
