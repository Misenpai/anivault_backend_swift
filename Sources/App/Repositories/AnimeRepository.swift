import Fluent
import Vapor

final class AnimeRepository {

    func findByUserAndMalId(userEmail: String, malId: Int, on db: any Database) async throws
        -> UserAnimeStatus?
    {
        return try await UserAnimeStatus.query(on: db)
            .filter(\.$id.$user.$id == userEmail)
            .filter(\.$id.$malId == malId)
            .first()
    }

    func create(_ animeStatus: UserAnimeStatus, on db: any Database) async throws {
        try await animeStatus.save(on: db)
    }

    func update(_ animeStatus: UserAnimeStatus, on db: any Database) async throws {
        try await animeStatus.save(on: db)
    }

    func delete(_ animeStatus: UserAnimeStatus, on db: any Database) async throws {
        try await animeStatus.delete(on: db)
    }

    func findByUser(userEmail: String, on db: any Database) async throws -> [UserAnimeStatus] {
        return try await UserAnimeStatus.query(on: db)
            .filter(\.$id.$user.$id == userEmail)
            .sort(\.$updatedAt, .descending)
            .all()
    }

    func findByUserAndStatus(userEmail: String, status: AnimeStatus, on db: any Database) async throws
        -> [UserAnimeStatus]
    {
        return try await UserAnimeStatus.query(on: db)
            .filter(\.$id.$user.$id == userEmail)
            .filter(\.$status == status)
            .sort(\.$updatedAt, .descending)
            .all()
    }

    func exists(userEmail: String, malId: Int, on db: any Database) async throws -> Bool {
        let count = try await UserAnimeStatus.query(on: db)
            .filter(\.$id.$user.$id == userEmail)
            .filter(\.$id.$malId == malId)
            .count()
        return count > 0
    }

    func countByStatus(userEmail: String, status: AnimeStatus, on db: any Database) async throws -> Int
    {
        return try await UserAnimeStatus.query(on: db)
            .filter(\.$id.$user.$id == userEmail)
            .filter(\.$status == status)
            .count()
    }

    func totalEpisodesWatched(userEmail: String, on db: any Database) async throws -> Int {
        let allAnime = try await findByUser(userEmail: userEmail, on: db)
        return allAnime.reduce(0) { $0 + $1.episodesWatched }
    }

    func completedCount(userEmail: String, on db: any Database) async throws -> Int {
        return try await countByStatus(userEmail: userEmail, status: .completed, on: db)
    }

    func watchingCount(userEmail: String, on db: any Database) async throws -> Int {
        return try await countByStatus(userEmail: userEmail, status: .watching, on: db)
    }

    func planToWatchCount(userEmail: String, on db: any Database) async throws -> Int {
        return try await countByStatus(userEmail: userEmail, status: .planToWatch, on: db)
    }

    func droppedCount(userEmail: String, on db: any Database) async throws -> Int {
        return try await countByStatus(userEmail: userEmail, status: .dropped, on: db)
    }

    func onHoldCount(userEmail: String, on db: any Database) async throws -> Int {
        return try await countByStatus(userEmail: userEmail, status: .onHold, on: db)
    }

    func totalAnimeCount(userEmail: String, on db: any Database) async throws -> Int {
        return try await UserAnimeStatus.query(on: db)
            .filter(\.$id.$user.$id == userEmail)
            .count()
    }

    func recentlyUpdated(userEmail: String, limit: Int, on db: any Database) async throws
        -> [UserAnimeStatus]
    {
        return try await UserAnimeStatus.query(on: db)
            .filter(\.$id.$user.$id == userEmail)
            .sort(\.$updatedAt, .descending)
            .limit(limit)
            .all()
    }

    func recentlyCompleted(userEmail: String, limit: Int, on db: any Database) async throws
        -> [UserAnimeStatus]
    {
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

    func findByMalIds(userEmail: String, malIds: [Int], on db: any Database) async throws
        -> [UserAnimeStatus]
    {
        return try await UserAnimeStatus.query(on: db)
            .filter(\.$id.$user.$id == userEmail)
            .filter(\.$id.$malId ~~ malIds)
            .all()
    }

    func searchByName(userEmail: String, query: String, on db: any Database) async throws
        -> [UserAnimeStatus]
    {
        return try await UserAnimeStatus.query(on: db)
            .filter(\.$id.$user.$id == userEmail)
            .filter(\.$animeName =~ query)
            .sort(\.$animeName, .ascending)
            .all()
    }

    func findWithScore(userEmail: String, on db: any Database) async throws -> [UserAnimeStatus] {
        return try await UserAnimeStatus.query(on: db)
            .filter(\.$id.$user.$id == userEmail)
            .group(.and) { group in
                group.filter(\.$score != nil)
            }
            .sort(\.$score, .descending)
            .all()
    }

    func averageScore(userEmail: String, on db: any Database) async throws -> Double {
        let animeWithScores = try await findWithScore(userEmail: userEmail, on: db)
        guard !animeWithScores.isEmpty else { return 0.0 }

        let totalScore = animeWithScores.compactMap { $0.score }.reduce(0.0, +)
        return totalScore / Double(animeWithScores.count)
    }

    func deleteAllForUser(userEmail: String, on db: any Database) async throws {
        try await UserAnimeStatus.query(on: db)
            .filter(\.$id.$user.$id == userEmail)
            .delete()
    }

    func bulkUpdateStatus(userEmail: String, malIds: [Int], newStatus: AnimeStatus, on db: any Database)
        async throws
    {
        let anime = try await UserAnimeStatus.query(on: db)
            .filter(\.$id.$user.$id == userEmail)
            .filter(\.$id.$malId ~~ malIds)
            .all()

        for item in anime {
            item.status = newStatus
            if newStatus == .completed {
                item.completedDate = Date()
                item.episodesWatched = item.totalEpisodes
            }
            try await item.save(on: db)
        }
    }

    func almostCompleted(userEmail: String, on db: any Database) async throws -> [UserAnimeStatus] {
        let allAnime = try await findByUser(userEmail: userEmail, on: db)
        return allAnime.filter { anime in
            guard anime.totalEpisodes > 0 else { return false }
            let progress = Double(anime.episodesWatched) / Double(anime.totalEpisodes)
            return progress >= 0.8 && anime.status != .completed
        }
    }

    func watchingByProgress(userEmail: String, on db: any Database) async throws -> [UserAnimeStatus] {
        let watching = try await findByUserAndStatus(
            userEmail: userEmail, status: .watching, on: db)
        return watching.sorted { anime1, anime2 in
            let progress1 =
                anime1.totalEpisodes > 0
                ? Double(anime1.episodesWatched) / Double(anime1.totalEpisodes) : 0
            let progress2 =
                anime2.totalEpisodes > 0
                ? Double(anime2.episodesWatched) / Double(anime2.totalEpisodes) : 0
            return progress1 > progress2
        }
    }
}