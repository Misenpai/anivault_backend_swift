import Vapor

struct CreateInviteRequest: Content {
    let maxUses: Int?
    let expiresInHours: Int?
}

struct CreateInviteResponse: Content {
    let inviteCode: String
    let maxUses: Int
    let expiresAt: Date?
}

struct AcceptInviteRequest: Content {
    let inviteCode: String
}

struct FriendDTO: Content {
    let email: String
    let username: String
    let friendshipStartedAt: Date
}

struct FriendStatsDTO: Content {
    let totalFriends: Int
}

struct PublicProfileDTO: Content {
    let username: String
    let animeStats: AnimeStatsDTO
    let isFriend: Bool
}
