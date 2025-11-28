import Fluent
import Vapor

struct ProfileController: RouteCollection {
    private let profileService: ProfileService

    init(profileService: ProfileService) {
        self.profileService = profileService
    }

    func boot(routes: any RoutesBuilder) throws {
        let profile = routes.grouped("profile")

        profile.get(":username", use: getPublicProfile)

        let protected = profile.grouped(JWTAuthenticationMiddleware())
        protected.get("me", "stats", use: getMyStats)
    }

    private func getPublicProfile(req: Request) async throws -> PublicProfileDTO {
        guard let username = req.parameters.get("username") else {
            throw Abort(.badRequest, reason: "Username required")
        }

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
