import Fluent
import SQLKit
import Vapor

final class FriendService {
    func createInvite(
        creatorEmail: String,
        maxUses: Int?,
        expiresInHours: Int?,
        on db: any Database
    ) async throws -> CreateInviteResponse {
        guard let sql = db as? any SQLDatabase else {
            throw Abort(.internalServerError, reason: "Database doesn't support SQL")
        }

        let result = try await sql.raw(
            """
            SELECT create_friend_invite(\(bind: creatorEmail), \(bind: maxUses ?? 1), \(bind: expiresInHours)) as invite_code
            """
        ).first(decoding: InviteCodeResult.self)

        guard let inviteCode = result?.inviteCode else {
            throw Abort(.internalServerError, reason: "Failed to create invite")
        }

        let invite = try await sql.raw(
            """
                SELECT max_uses, expires_at
                FROM friend_invites
                WHERE invite_code = \(bind: inviteCode)
            """
        ).first(decoding: InviteDetails.self)

        return CreateInviteResponse(
            inviteCode: inviteCode,
            maxUses: invite?.maxUses ?? 1,
            expiresAt: invite?.expiresAt
        )
    }

    func acceptInvite(inviteCode: String, accepterEmail: String, on db: any Database) async throws
        -> String
    {
        guard let sql = db as? any SQLDatabase else {
            throw Abort(.internalServerError, reason: "Database doesn't support SQL")
        }

        let result = try await sql.raw(
            """
            SELECT accept_friend_invite(\(bind: inviteCode), \(bind: accepterEmail)) as message
            """
        ).first(decoding: MessageResult.self)

        guard let message = result?.message else {
            throw Abort(.internalServerError, reason: "Failed to accept invite")
        }

        if message.contains("Successfully") {
            return message
        } else {
            throw Abort(.badRequest, reason: message)
        }
    }

    func getFriends(userEmail: String, on db: any Database) async throws -> [FriendDTO] {
        guard let sql = db as? any SQLDatabase else {
            throw Abort(.internalServerError, reason: "Database doesn't support SQL")
        }

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

        let friends = try await sql.raw(
            """
                SELECT * FROM get_user_friends(\(bind: userEmail))
            """
        ).all(decoding: FriendRow.self)

        return friends.map {
            FriendDTO(
                email: $0.friendEmail,
                username: $0.friendUsername,
                friendshipStartedAt: $0.friendshipStartedAt
            )
        }
    }

    func getFriendCount(userEmail: String, on db: any Database) async throws -> Int {
        guard let sql = db as? any SQLDatabase else {
            throw Abort(.internalServerError, reason: "Database doesn't support SQL")
        }

        let result = try await sql.raw(
            """
            SELECT total_friends FROM v_user_social_stats WHERE email = \(bind: userEmail)
            """
        ).first(decoding: FriendCountResult.self)

        return result?.totalFriends ?? 0
    }

    func removeFriend(userEmail: String, friendEmail: String, on db: any Database) async throws
        -> String
    {
        guard let sql = db as? any SQLDatabase else {
            throw Abort(.internalServerError, reason: "Database doesn't support SQL")
        }

        let result = try await sql.raw(
            """
            SELECT remove_friendship(\(bind: userEmail), \(bind: friendEmail)) as message
            """
        ).first(decoding: MessageResult.self)

        return result?.message ?? "Failed to remove friend"
    }

    func areFriends(email1: String, email2: String, on db: any Database) async throws -> Bool {
        guard let sql = db as? any SQLDatabase else {
            throw Abort(.internalServerError, reason: "Database doesn't support SQL")
        }

        let result = try await sql.raw(
            """
            SELECT are_friends(\(bind: email1), \(bind: email2)) as is_friend
            """
        ).first(decoding: IsFriendResult.self)

        return result?.isFriend ?? false
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
