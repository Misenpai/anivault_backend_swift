//
//  AnimeService.swift
//  anivault_backend
//
//  Created by Sumit Sinha on 09/11/25.
//

import Fluent
import Vapor

final class AnimeService {
    private let animeRepository: AnimeRepository

    init(animeRepository: AnimeRepository) {
        self.animeRepository = animeRepository
    }

    func addAnimeStatus(
        userEmail: String,
        malId: Int,
        animeName: String,
        totalEpisodes: Int,
        status: AnimeStatus,
        on db: Database
    ) async throws -> UserAnimeStatus {
        if let existing = try await animeRepository.findByUserAndMalId(
            userEmail: userEmail,
            malId: malId,
            on: db
        ) {
            throw Abort(.conflict, reason: "Anime already in your list")
        }

        guard totalEpisodes > 0 else {
            throw Abort(.badRequest, reason: "Total episodes must be greater than 0")
        }

        let animeStatus = UserAnimeStatus(
            userEmail: userEmail,
            malId: malId,
            animeName: animeName,
            totalEpisodes: totalEpisodes,
            status: status
        )

        if status == .watching {
            animeStatus.startedDate = Date()
        } else if status == .completed {
            animeStatus.startedDate = Date()
            animeStatus.completedDate = Date()
            animeStatus.totalWatchedEpisodes = totalEpisodes
        }

        try await animeRepository.create(animeStatus, on: db)
        return animeStatus
    }

    func updateAnimeStatus(
        userEmail: String,
        malId: Int,
        watchedEpisodes: Int?,
        status: AnimeStatus?,
        score: Double?,
        on db: Database
    ) async throws -> UserAnimeStatus {
        guard
            let animeStatus = try await animeRepository.findByUserAndMalId(
                userEmail: userEmail,
                malId: malId,
                on: db
            )
        else {
            throw Abort(.notFound, reason: "Anime not found in your list")
        }

        if let watchedEpisodes = watchedEpisodes {
            guard watchedEpisodes >= 0 else {
                throw Abort(.badRequest, reason: "Episodes watched cannot be negative")
            }

            guard watchedEpisodes <= animeStatus.totalEpisodes else {
                throw Abort(.badRequest, reason: "Episodes watched cannot exceed total episodes")
            }

            animeStatus.totalWatchedEpisodes = watchedEpisodes
        }

        if let newStatus = status {
            let oldStatus = animeStatus.status
            animeStatus.status = newStatus

            switch newStatus {
            case .watching:
                if animeStatus.startedDate == nil {
                    animeStatus.startedDate = Date()
                }

            case .completed:
                animeStatus.totalWatchedEpisodes = animeStatus.totalEpisodes

                if animeStatus.startedDate == nil {
                    animeStatus.startedDate = Date()
                }
                if animeStatus.completedDate == nil {
                    animeStatus.completedDate = Date()
                }

            case .dropped, .onHold:
                if oldStatus == .completed {
                    animeStatus.completedDate = nil
                }

            case .planToWatch:
                animeStatus.totalWatchedEpisodes = 0
                animeStatus.startedDate = nil
                animeStatus.completedDate = nil
            }
        }

        if let score = score {
            guard score >= 0 && score <= 10 else {
                throw Abort(.badRequest, reason: "Score must be between 0 and 10")
            }
            animeStatus.score = score == 0 ? nil : score
        }

        try await animeRepository.update(animeStatus, on: db)
        return animeStatus
    }

    func removeAnimeStatus(userEmail: String, malId: Int, on db: Database) async throws {
        guard
            let animeStatus = try await animeRepository.findByUserAndMalId(
                userEmail: userEmail,
                malId: malId,
                on: db
            )
        else {
            throw Abort(.notFound, reason: "Anime not found in your list")
        }

        try await animeRepository.delete(animeStatus, on: db)
    }

    func getUserAnimeByStatus(
        userEmail: String,
        status: AnimeStatus,
        on db: Database
    ) async throws -> [UserAnimeStatus] {
        return try await animeRepository.findByUserAndStatus(
            userEmail: userEmail,
            status: status,
            on: db
        )
    }

    func getAnimeStatus(
        userEmail: String,
        malId: Int,
        on db: Database
    ) async throws -> UserAnimeStatus? {
        return try await animeRepository.findByUserAndMalId(
            userEmail: userEmail,
            malId: malId,
            on: db
        )
    }

    func getAllUserAnime(userEmail: String, on db: Database) async throws -> [UserAnimeStatus] {
        return try await animeRepository.findByUser(userEmail: userEmail, on: db)
    }

    func getUserAnimeStats(userEmail: String, on db: Database) async throws -> AnimeStatsDTO {
        let watching = try await animeRepository.watchingCount(userEmail: userEmail, on: db)
        let completed = try await animeRepository.completedCount(userEmail: userEmail, on: db)
        let planToWatch = try await animeRepository.planToWatchCount(userEmail: userEmail, on: db)
        let dropped = try await animeRepository.droppedCount(userEmail: userEmail, on: db)
        let onHold = try await animeRepository.onHoldCount(userEmail: userEmail, on: db)
        let totalAnime = try await animeRepository.totalAnimeCount(userEmail: userEmail, on: db)
        let totalEpisodes = try await animeRepository.totalEpisodesWatched(
            userEmail: userEmail, on: db)
        let avgScore = try await animeRepository.averageScore(userEmail: userEmail, on: db)

        return AnimeStatsDTO(
            watching: watching,
            completed: completed,
            planToWatch: planToWatch,
            dropped: dropped,
            onHold: onHold,
            totalAnime: totalAnime,
            totalEpisodesWatched: totalEpisodes,
            averageScore: avgScore > 0 ? avgScore : nil
        )
    }

    func searchUserAnime(
        userEmail: String,
        query: String,
        on db: Database
    ) async throws -> [UserAnimeStatus] {
        guard !query.isEmpty else {
            return try await animeRepository.findByUser(userEmail: userEmail, on: db)
        }

        return try await animeRepository.searchByName(
            userEmail: userEmail,
            query: query,
            on: db
        )
    }

    func getRecentlyUpdated(
        userEmail: String,
        limit: Int = 10,
        on db: Database
    ) async throws -> [UserAnimeStatus] {
        return try await animeRepository.recentlyUpdated(
            userEmail: userEmail,
            limit: limit,
            on: db
        )
    }

    func getRecentlyCompleted(
        userEmail: String,
        limit: Int = 10,
        on db: Database
    ) async throws -> [UserAnimeStatus] {
        return try await animeRepository.recentlyCompleted(
            userEmail: userEmail,
            limit: limit,
            on: db
        )
    }
}
