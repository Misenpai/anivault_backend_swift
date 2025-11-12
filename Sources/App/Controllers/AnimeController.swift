//
//  AnimeController.swift
//  anivault_backend
//
//  Created by Sumit Sinha on 09/11/25.
//

import Vapor
import Fluent

final class AnimeController: RouteCollection {
    private let jikanService: JikanService
    private let animeService: AnimeService
    
    init(jikanService: JikanService, animeService: AnimeService) {
        self.jikanService = jikanService
        self.animeService = animeService
    }
    
    func boot(routes: RoutesBuilder) throws {
        let anime = routes.grouped("anime")
        
        // Jikan proxy endpoints (public)
        anime.get(":id", use: getAnimeById)
        anime.get("search", use: searchAnime)
        anime.get("season", "now", use: getCurrentSeason)
        anime.get("season", "upcoming", use: getUpcomingSeason)
        anime.get("season", ":year", ":season", use: getSeasonAnime)
        anime.get("top", use: getTopAnime)
        
        // User anime list endpoints (protected)
        let protected = anime.grouped(JWTAuthenticationMiddleware())
        let userAnime = protected.grouped("user")
        userAnime.post(use: addAnimeToList)
        userAnime.put(use: updateAnimeStatus)
        userAnime.delete(":malId", use: deleteAnimeFromList)
        userAnime.get("status", ":status", use: getAnimeByStatus)
        userAnime.get(":malId", use: checkAnimeStatus)
    }
    
    // MARK: - Jikan Proxy Endpoints
    
    private func getAnimeById(req: Request) async throws -> AnimeResponse {
        guard let id = req.parameters.get("id", as: Int.self) else {
            throw Abort(.badRequest, reason: "Invalid anime ID")
        }
        return try await jikanService.getAnimeById(id)
    }
    
    private func searchAnime(req: Request) async throws -> SeasonAnimeResponse {
        guard let query = req.query[String.self, at: "q"] else {
            throw Abort(.badRequest, reason: "Search query required")
        }
        let page = req.query[Int.self, at: "page"] ?? 1
        let limit = req.query[Int.self, at: "limit"] ?? 25
        
        return try await jikanService.searchAnime(query: query, page: page, limit: limit)
    }
    
    private func getCurrentSeason(req: Request) async throws -> SeasonAnimeResponse {
        let page = req.query[Int.self, at: "page"] ?? 1
        let limit = req.query[Int.self, at: "limit"] ?? 25
        
        return try await jikanService.getCurrentSeasonAnime(page: page, limit: limit)
    }
    
    private func getUpcomingSeason(req: Request) async throws -> SeasonAnimeResponse {
        let page = req.query[Int.self, at: "page"] ?? 1
        let limit = req.query[Int.self, at: "limit"] ?? 25
        
        return try await jikanService.getUpcomingSeasonAnime(page: page, limit: limit)
    }
    
    private func getSeasonAnime(req: Request) async throws -> SeasonAnimeResponse {
        guard let year = req.parameters.get("year", as: Int.self),
              let season = req.parameters.get("season") else {
            throw Abort(.badRequest, reason: "Year and season required")
        }
        let page = req.query[Int.self, at: "page"] ?? 1
        
        return try await jikanService.getSeasonAnime(year: year, season: season, page: page)
    }
    
    private func getTopAnime(req: Request) async throws -> SeasonAnimeResponse {
        let page = req.query[Int.self, at: "page"] ?? 1
        let limit = req.query[Int.self, at: "limit"] ?? 25
        
        return try await jikanService.getTopAnime(page: page, limit: limit)
    }
    
    // MARK: - User Anime List Endpoints
    
    private func addAnimeToList(req: Request) async throws -> UserAnimeStatus {
        let user = try req.auth.require(User.self)
        let request = try req.content.decode(AddAnimeStatusRequest.self)
        
        return try await animeService.addAnimeStatus(
            userEmail: user.id!,
            malId: request.malId,
            animeName: request.animeName,
            totalEpisodes: request.totalEpisodes,
            status: AnimeStatus(rawValue: request.status) ?? .planToWatch,
            on: req.db
        )
    }
    
    private func updateAnimeStatus(req: Request) async throws -> UserAnimeStatus {
        let user = try req.auth.require(User.self)
        let request = try req.content.decode(UpdateAnimeStatusRequest.self)
        
        return try await animeService.updateAnimeStatus(
            userEmail: user.id!,
            malId: request.malId,
            watchedEpisodes: request.totalWatchedEpisodes,
            status: AnimeStatus(rawValue: request.status),
            score: nil,
            on: req.db
        )
    }
    
    private func deleteAnimeFromList(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        guard let malId = req.parameters.get("malId", as: Int.self) else {
            throw Abort(.badRequest, reason: "Invalid MAL ID")
        }
        
        try await animeService.removeAnimeStatus(userEmail: user.id!, malId: malId, on: req.db)
        return .noContent
    }
    
    private func getAnimeByStatus(req: Request) async throws -> [UserAnimeStatus] {
        let user = try req.auth.require(User.self)
        guard let statusString = req.parameters.get("status"),
              let status = AnimeStatus(rawValue: statusString) else {
            throw Abort(.badRequest, reason: "Invalid status")
        }
        
        return try await animeService.getUserAnimeByStatus(
            userEmail: user.id!,
            status: status,
            on: req.db
        )
    }
    
    private func checkAnimeStatus(req: Request) async throws -> UserAnimeStatus {
        let user = try req.auth.require(User.self)
        guard let malId = req.parameters.get("malId", as: Int.self) else {
            throw Abort(.badRequest, reason: "Invalid MAL ID")
        }
        
        guard let anime = try await animeService.getAnimeStatus(
            userEmail: user.id!,
            malId: malId,
            on: req.db
        ) else {
            throw Abort(.notFound, reason: "Anime not in your list")
        }
        
        return anime
    }
}

// Supporting DTOs
struct AddAnimeStatusRequest: Content {
    let malId: Int
    let animeName: String
    let totalEpisodes: Int
    let status: String
}

struct UpdateAnimeStatusRequest: Content {
    let malId: Int
    let totalWatchedEpisodes: Int
    let status: String
}
