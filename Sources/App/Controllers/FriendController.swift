//
//  FriendController.swift
//  anivault_backend
//
//  Created by Sumit Sinha on 09/11/25.
//

import Vapor
import Fluent

final class FriendController: RouteCollection {
    private let friendService: FriendService
    
    init(friendService: FriendService) {
        self.friendService = friendService
    }
    
    func boot(routes: RoutesBuilder) throws {
        let friends = routes.grouped("friends")
            .grouped(JWTAuthenticationMiddleware())
        
        friends.get(use: getMyFriends)
        friends.get("count", use: getFriendCount)
        friends.delete(":email", use: removeFriend)
        
        // Invite routes
        let invites = friends.grouped("invite")
        invites.post("create", use: createInvite)
        invites.post("accept", use: acceptInvite)
    }
    
    private func createInvite(req: Request) async throws -> CreateInviteResponse {
        let user = try req.auth.require(User.self)
        let request = try req.content.decode(CreateInviteRequest.self)
        
        return try await friendService.createInvite(
            creatorEmail: user.id!,
            maxUses: request.maxUses,
            expiresInHours: request.expiresInHours,
            on: req.db
        )
    }
    
    private func acceptInvite(req: Request) async throws -> [String: String] {
        let user = try req.auth.require(User.self)
        let request = try req.content.decode(AcceptInviteRequest.self)
        
        let message = try await friendService.acceptInvite(
            inviteCode: request.inviteCode,
            accepterEmail: user.id!,
            on: req.db
        )
        
        return ["message": message]
    }
    
    private func getMyFriends(req: Request) async throws -> [FriendDTO] {
        let user = try req.auth.require(User.self)
        return try await friendService.getFriends(userEmail: user.id!, on: req.db)
    }
    
    private func getFriendCount(req: Request) async throws -> FriendStatsDTO {
        let user = try req.auth.require(User.self)
        let count = try await friendService.getFriendCount(userEmail: user.id!, on: req.db)
        return FriendStatsDTO(totalFriends: count)
    }
    
    private func removeFriend(req: Request) async throws -> [String: String] {
        let user = try req.auth.require(User.self)
        guard let friendEmail = req.parameters.get("email") else {
            throw Abort(.badRequest, reason: "Friend email required")
        }
        
        let message = try await friendService.removeFriend(
            userEmail: user.id!,
            friendEmail: friendEmail,
            on: req.db
        )
        
        return ["message": message]
    }
}
