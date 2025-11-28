import Fluent
import SQLKit
import Vapor

final actor FriendService {
    private let friendRepository: FriendRepository

    init(friendRepository: FriendRepository) {
        self.friendRepository = friendRepository
    }

    func createInvite(
        creatorEmail: String,
        maxUses: Int?,
        expiresInHours: Int?,
        on db: any Database
    ) async throws -> CreateInviteResponse {
        guard
            let result = try await friendRepository.createInvite(
                creatorEmail: creatorEmail,
                maxUses: maxUses ?? 1,
                expiresInHours: expiresInHours,
                on: db
            )
        else {
            throw Abort(.internalServerError, reason: "Failed to create invite")
        }

        let inviteCode = result.inviteCode

        guard
            let invite = try await friendRepository.getInviteDetails(inviteCode: inviteCode, on: db)
        else {
            // This should technically not happen if create succeeded, but good to handle
            throw Abort(.internalServerError, reason: "Failed to retrieve created invite details")
        }

        return CreateInviteResponse(
            inviteCode: inviteCode,
            maxUses: invite.maxUses,
            expiresAt: invite.expiresAt
        )
    }

    func acceptInvite(inviteCode: String, accepterEmail: String, on db: any Database) async throws
        -> String
    {
        guard
            let result = try await friendRepository.acceptInvite(
                inviteCode: inviteCode,
                accepterEmail: accepterEmail,
                on: db
            )
        else {
            throw Abort(.internalServerError, reason: "Failed to accept invite")
        }

        let message = result.message
        if message.contains("Successfully") {
            return message
        } else {
            throw Abort(.badRequest, reason: message)
        }
    }

    func getFriends(userEmail: String, on db: any Database) async throws -> [FriendDTO] {
        let friends = try await friendRepository.getFriends(userEmail: userEmail, on: db)

        return friends.map {
            FriendDTO(
                email: $0.friendEmail,
                username: $0.friendUsername,
                friendshipStartedAt: $0.friendshipStartedAt
            )
        }
    }

    func getFriendCount(userEmail: String, on db: any Database) async throws -> Int {
        let result = try await friendRepository.getFriendCount(userEmail: userEmail, on: db)
        return result?.totalFriends ?? 0
    }

    func removeFriend(userEmail: String, friendEmail: String, on db: any Database) async throws
        -> String
    {
        let result = try await friendRepository.removeFriend(
            userEmail: userEmail,
            friendEmail: friendEmail,
            on: db
        )
        return result?.message ?? "Failed to remove friend"
    }

    func areFriends(email1: String, email2: String, on db: any Database) async throws -> Bool {
        let result = try await friendRepository.areFriends(email1: email1, email2: email2, on: db)
        return result?.isFriend ?? false
    }
}
