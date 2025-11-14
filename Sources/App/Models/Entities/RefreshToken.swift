// Sources/App/Models/Entities/RefreshToken.swift
import Fluent
import Vapor

final class RefreshToken: Model, Content, @unchecked Sendable {
    static let schema = "refresh_tokens"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "token")
    var token: String
    
    @Field(key: "user_email")
    var userEmail: String
    
    @Timestamp(key: "expires_at", on: .none)
    var expiresAt: Date?
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Field(key: "is_revoked")
    var isRevoked: Bool
    
    init() {}
    
    init(token: String, userEmail: String, expiresAt: Date) {
        self.token = token
        self.userEmail = userEmail
        self.expiresAt = expiresAt
        self.isRevoked = false
    }
}