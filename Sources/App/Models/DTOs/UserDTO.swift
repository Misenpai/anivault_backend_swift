//
//  UserDTO.swift
//  anivault_backend
//
//  Created by Sumit Sinha on 08/11/25.
//

import Vapor

struct UserDTO: Content {
    let email: String
    let username: String
    let roleId: Int
    let emailVerified: Bool
    let createdAt: Date?
    let lastLogin: Date?
}

struct UserProfileDTO: Content{
    let email: String
    let username: String
    let roleId: Int
    let roleTitle: String
    let emailVerified: Bool
    let createdAt: Date?
    let lastLogin: Date?
    let totalFriends: Int?
}

struct UserSummaryDTO: Content {
    let email: String
    let username: String
}


struct UserPatchRequest: Content {
    let username: String?
    let password: String?
}

struct UserStatsDTO: Content {
    let totalUsers: Int
    let verifiedUsers: Int
    let usersToday: Int
    let activeUsers: Int
}

struct UserWithAnimeStatsDTO: Content {
    let email: String
    let username: String
    let emailVerified: Bool
    let animeStats: UserAnimeStatsDTO
}

struct UserAnimeStatsDTO: Content {
    let totalAnime: Int
    let watching: Int
    let completed: Int
    let planToWatch: Int
    let dropped: Int
    let onHold: Int
    let totalEpisodesWatched: Int
    let averageScore: Double?
}


extension User {
    func toDTO() -> UserDTO {
        return UserDTO(
            email: self.id ?? "",
            username: self.username,
            roleId: self.roleId,
            emailVerified: self.emailVerified,
            createdAt: self.createdAt,
            lastLogin: self.lastLogin
        )
    }
    
    func toSummaryDTO() -> UserSummaryDTO {
        return UserSummaryDTO(
            email: self.id ?? "",
            username: self.username
        )
    }
}
