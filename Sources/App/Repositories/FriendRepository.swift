import Fluent
import SQLKit
import Vapor

struct FriendRepository {
    func createInvite(creatorEmail: String, maxUses: Int, expiresInHours: Int?, on db: any Database)
        async throws -> InviteCodeResult?
    {
        guard let sql = db as? any SQLDatabase else {
            throw Abort(.internalServerError, reason: "Database doesn't support SQL")
        }

        return try await sql.raw(
            """
            SELECT create_friend_invite(\(bind: creatorEmail), \(bind: maxUses), \(bind: expiresInHours)) as invite_code
            """
        ).first(decoding: InviteCodeResult.self)
    }

    func getInviteDetails(inviteCode: String, on db: any Database) async throws -> InviteDetails? {
        guard let sql = db as? any SQLDatabase else {
            throw Abort(.internalServerError, reason: "Database doesn't support SQL")
        }

        return try await sql.raw(
            """
                SELECT max_uses, expires_at
                FROM friend_invites
                WHERE invite_code = \(bind: inviteCode)
            """
        ).first(decoding: InviteDetails.self)
    }

    func acceptInvite(inviteCode: String, accepterEmail: String, on db: any Database) async throws
        -> MessageResult?
    {
        guard let sql = db as? any SQLDatabase else {
            throw Abort(.internalServerError, reason: "Database doesn't support SQL")
        }

        return try await sql.raw(
            """
            SELECT accept_friend_invite(\(bind: inviteCode), \(bind: accepterEmail)) as message
            """
        ).first(decoding: MessageResult.self)
    }

    func getFriends(userEmail: String, on db: any Database) async throws -> [FriendRow] {
        guard let sql = db as? any SQLDatabase else {
            throw Abort(.internalServerError, reason: "Database doesn't support SQL")
        }

        return try await sql.raw(
            """
                SELECT * FROM get_user_friends(\(bind: userEmail))
            """
        ).all(decoding: FriendRow.self)
    }

    func getFriendCount(userEmail: String, on db: any Database) async throws -> FriendCountResult? {
        guard let sql = db as? any SQLDatabase else {
            throw Abort(.internalServerError, reason: "Database doesn't support SQL")
        }

        return try await sql.raw(
            """
            SELECT total_friends FROM v_user_social_stats WHERE email = \(bind: userEmail)
            """
        ).first(decoding: FriendCountResult.self)
    }

    func removeFriend(userEmail: String, friendEmail: String, on db: any Database) async throws
        -> MessageResult?
    {
        guard let sql = db as? any SQLDatabase else {
            throw Abort(.internalServerError, reason: "Database doesn't support SQL")
        }

        return try await sql.raw(
            """
            SELECT remove_friendship(\(bind: userEmail), \(bind: friendEmail)) as message
            """
        ).first(decoding: MessageResult.self)
    }

    func areFriends(email1: String, email2: String, on db: any Database) async throws
        -> IsFriendResult?
    {
        guard let sql = db as? any SQLDatabase else {
            throw Abort(.internalServerError, reason: "Database doesn't support SQL")
        }

        return try await sql.raw(
            """
            SELECT are_friends(\(bind: email1), \(bind: email2)) as is_friend
            """
        ).first(decoding: IsFriendResult.self)
    }
}

// Models needed for decoding
struct FriendRow: Decodable {
    let friendEmail: String
    let friendUsername: String
    let friendshipStartedAt: Date

    enum CodingKeys: String, CodingKey {
        case friendEmail = "friend_email"
        case friendUsername = "friend_username"
        case friendshipStartedAt = "friendship_started_at"
    }
}

struct InviteCodeResult: Decodable {
    let inviteCode: String

    enum CodingKeys: String, CodingKey {
        case inviteCode = "invite_code"
    }
}

struct InviteDetails: Decodable {
    let maxUses: Int
    let expiresAt: Date?

    enum CodingKeys: String, CodingKey {
        case maxUses = "max_uses"
        case expiresAt = "expires_at"
    }
}

struct MessageResult: Decodable {
    let message: String
}

struct FriendCountResult: Decodable {
    let totalFriends: Int

    enum CodingKeys: String, CodingKey {
        case totalFriends = "total_friends"
    }
}

struct IsFriendResult: Decodable {
    let isFriend: Bool

    enum CodingKeys: String, CodingKey {
        case isFriend = "is_friend"
    }
}
