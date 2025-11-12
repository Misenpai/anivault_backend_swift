//
//  AnimeRepository.swift
//  anivault_backend
//
//  Created by Sumit Sinha on 11/11/25.
//

import Fluent
import Vapor

final class AnimeRepository {
    
    /// Find anime status by user email and MAL ID
    func findByUserAndMalId(userEmail: String, malId: Int, on db: Database) async throws -> UserAnimeStatus? {
        return try await UserAnimeStatus.query(on: db)
            .filter(\.$id.$user.$id == userEmail)
            .filter(\.$id.$malId == malId)
            .first()
    }
    
    /// Create anime status
    func create(_ animeStatus: UserAnimeStatus, on db: Database) async throws {
        try await animeStatus.save(on: db)
    }
    
    /// Update anime status
    func update(_ animeStatus: UserAnimeStatus, on db: Database) async throws {
        try await animeStatus.save(on: db)
    }
    
    /// Delete anime status
    func delete(_ animeStatus: UserAnimeStatus, on db: Database) async throws {
        try await animeStatus.delete(on: db)
    }
    
    /// Find all anime for a user
    func findByUser(userEmail: String, on db: Database) async throws -> [UserAnimeStatus] {
        return try await UserAnimeStatus.query(on: db)
            .filter(\.$id.$user.$id == userEmail)
            .sort(\.$updatedAt, .descending)
            .all()
    }
    
    /// Find anime by user and status
    func findByUserAndStatus(userEmail: String, status: AnimeStatus, on db: Database) async throws -> [UserAnimeStatus] {
        return try await UserAnimeStatus.query(on: db)
            .filter(\.$id.$user.$id == userEmail)
            .filter(\.$status == status)
            .sort(\.$updatedAt, .descending)
            .all()
    }
    
    /// Check if user has anime in their list
    func exists(userEmail: String, malId: Int, on db: Database) async throws -> Bool {
        let count = try await UserAnimeStatus.query(on: db)
            .filter(\.$id.$user.$id == userEmail)
            .filter(\.$id.$malId == malId)
            .count()
        return count > 0
    }
    
    /// Get user's anime count by status
    func countByStatus(userEmail: String, status: AnimeStatus, on db: Database) async throws -> Int {
        return try await UserAnimeStatus.query(on: db)
            .filter(\.$id.$user.$id == userEmail)
            .filter(\.$status == status)
            .count()
    }
    
    /// Get total episodes watched by user
    func totalEpisodesWatched(userEmail: String, on db: Database) async throws -> Int {
        let allAnime = try await findByUser(userEmail: userEmail, on: db)
        return allAnime.reduce(0) { $0 + $1.totalWatchedEpisodes }
    }
    
    /// Get user's completed anime count
    func completedCount(userEmail: String, on db: Database) async throws -> Int {
        return try await countByStatus(userEmail: userEmail, status: .completed, on: db)
    }
    
    /// Get user's watching anime count
    func watchingCount(userEmail: String, on db: Database) async throws -> Int {
        return try await countByStatus(userEmail: userEmail, status: .watching, on: db)
    }
    
    /// Get user's plan to watch count
    func planToWatchCount(userEmail: String, on db: Database) async throws -> Int {
        return try await countByStatus(userEmail: userEmail, status: .planToWatch, on: db)
    }
    
    /// Get user's dropped anime count
    func droppedCount(userEmail: String, on db: Database) async throws -> Int {
        return try await countByStatus(userEmail: userEmail, status: .dropped, on: db)
    }
    
    /// Get user's on hold anime count
    func onHoldCount(userEmail: String, on db: Database) async throws -> Int {
        return try await countByStatus(userEmail: userEmail, status: .onHold, on: db)
    }
    
    /// Get total anime in user's list
    func totalAnimeCount(userEmail: String, on db: Database) async throws -> Int {
        return try await UserAnimeStatus.query(on: db)
            .filter(\.$id.$user.$id == userEmail)
            .count()
    }
    
    /// Get recently updated anime for user
    func recentlyUpdated(userEmail: String, limit: Int, on db: Database) async throws -> [UserAnimeStatus] {
        return try await UserAnimeStatus.query(on: db)
            .filter(\.$id.$user.$id == userEmail)
            .sort(\.$updatedAt, .descending)
            .limit(limit)
            .all()
    }
    
    /// Get recently completed anime for user
    func recentlyCompleted(userEmail: String, limit: Int, on db: Database) async throws -> [UserAnimeStatus] {
        return try await UserAnimeStatus.query(on: db)
            .filter(\.$id.$user.$id == userEmail)
            .filter(\.$status == .completed)
            .group(.and) { group in
                group.filter(\.$completedDate != nil)
            }
            .sort(\.$completedDate, .descending)
            .limit(limit)
            .all()
    }
    
    /// Get anime by MAL IDs for user
    func findByMalIds(userEmail: String, malIds: [Int], on db: Database) async throws -> [UserAnimeStatus] {
        return try await UserAnimeStatus.query(on: db)
            .filter(\.$id.$user.$id == userEmail)
            .filter(\.$id.$malId ~~ malIds)
            .all()
    }
    
    /// Search anime in user's list by name
    func searchByName(userEmail: String, query: String, on db: Database) async throws -> [UserAnimeStatus] {
        return try await UserAnimeStatus.query(on: db)
            .filter(\.$id.$user.$id == userEmail)
            .filter(\.$animeName =~ query)
            .sort(\.$animeName, .ascending)
            .all()
    }
    
    /// Get anime with score
    func findWithScore(userEmail: String, on db: Database) async throws -> [UserAnimeStatus] {
        return try await UserAnimeStatus.query(on: db)
            .filter(\.$id.$user.$id == userEmail)
            .group(.and) { group in
                group.filter(\.$score != nil)
            }
            .sort(\.$score, .descending)
            .all()
    }
    
    /// Get average score for user's anime
    func averageScore(userEmail: String, on db: Database) async throws -> Double {
        let animeWithScores = try await findWithScore(userEmail: userEmail, on: db)
        guard !animeWithScores.isEmpty else { return 0.0 }
        
        let totalScore = animeWithScores.compactMap { $0.score }.reduce(0.0, +)
        return totalScore / Double(animeWithScores.count)
    }
    
    /// Delete all anime for user (cascade delete)
    func deleteAllForUser(userEmail: String, on db: Database) async throws {
        try await UserAnimeStatus.query(on: db)
            .filter(\.$id.$user.$id == userEmail)
            .delete()
    }
    
    /// Bulk update status for multiple anime
    func bulkUpdateStatus(userEmail: String, malIds: [Int], newStatus: AnimeStatus, on db: Database) async throws {
        let anime = try await UserAnimeStatus.query(on: db)
            .filter(\.$id.$user.$id == userEmail)
            .filter(\.$id.$malId ~~ malIds)
            .all()
        
        for item in anime {
            item.status = newStatus
            if newStatus == .completed {
                item.completedDate = Date()
                item.totalWatchedEpisodes = item.totalEpisodes
            }
            try await item.save(on: db)
        }
    }
    
    /// Get anime that are close to completion (80%+ watched)
    func almostCompleted(userEmail: String, on db: Database) async throws -> [UserAnimeStatus] {
        let allAnime = try await findByUser(userEmail: userEmail, on: db)
        return allAnime.filter { anime in
            guard anime.totalEpisodes > 0 else { return false }
            let progress = Double(anime.totalWatchedEpisodes) / Double(anime.totalEpisodes)
            return progress >= 0.8 && anime.status != .completed
        }
    }
    
    /// Get watching anime sorted by progress
    func watchingByProgress(userEmail: String, on db: Database) async throws -> [UserAnimeStatus] {
        let watching = try await findByUserAndStatus(userEmail: userEmail, status: .watching, on: db)
        return watching.sorted { anime1, anime2 in
            let progress1 = anime1.totalEpisodes > 0 ?
                Double(anime1.totalWatchedEpisodes) / Double(anime1.totalEpisodes) : 0
            let progress2 = anime2.totalEpisodes > 0 ?
                Double(anime2.totalWatchedEpisodes) / Double(anime2.totalEpisodes) : 0
            return progress1 > progress2
        }
    }
}
