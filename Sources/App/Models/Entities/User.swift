//
//  User.swift
//  anivault_backend
//
//  Created by Sumit Sinha on 08/11/25.
//

import Fluent
import Vapor

final class User: Model, Content {
    static let schema = "users"
    
    @ID(custom: "email", generatedBy: .user)
    var id: String?
    
    @Field(key: "username")
    var username: String
    
    @Field(key: "password_hash")
    var passwordHash: String
    
    @Field(key: "role_id")
    var roleId: Int
    
    @Field(key: "email_verified")
    var emailVerified: Bool
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "last_login", on: .none)
    var lastLogin: Date?
    
    @Field(key: "profile_image")
    var profileImage: String?
    
    @Field(key: "bio")
    var bio: String?
    
    @Parent(key: "role_id")
    var role: Role
    
    @Children(for: \.$user)
    var animeStatuses: [UserAnimeStatus]
    
    init() { }
    
    init(email: String, username: String, passwordHash: String, roleId: Int = 2) {
        self.id = email
        self.username = username
        self.passwordHash = passwordHash
        self.roleId = roleId
        self.emailVerified = false
    }
}

extension User: ModelAuthenticatable {
    static let usernameKey = \User.$id  // Email is the identifier
    static let passwordHashKey = \User.$passwordHash
    
    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }
}
