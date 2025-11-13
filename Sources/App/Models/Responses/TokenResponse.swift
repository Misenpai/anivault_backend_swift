//
//  TokenResponse.swift
//  anivault_backend
//
//  Created by Sumit Sinha on 08/11/25.
//

import Vapor
import JWTKit

struct TokenResponse: Content {
    let success: Bool
    let token: String
    let user: UserDTO
    let expiresAt: Date
    let tokenType: String
    
    enum CodingKeys: String, CodingKey {
        case success
        case token
        case user
        case expiresAt = "expires_at"
        case tokenType = "token_type"
    }
    
    init(token: String, user: UserDTO, expiresAt: Date) {
        self.success = true
        self.token = token
        self.user = user
        self.expiresAt = expiresAt
        self.tokenType = "Bearer"
    }
}

struct RefreshTokenResponse: Content {
    let success: Bool
    let token: String
    let expiresAt: Date
    let tokenType: String
    
    enum CodingKeys: String, CodingKey {
        case success
        case token
        case expiresAt = "expires_at"
        case tokenType = "token_type"
    }
    
    init(token: String, expiresAt: Date) {
        self.success = true
        self.token = token
        self.expiresAt = expiresAt
        self.tokenType = "Bearer"
    }
}

struct TokenValidationResponse: Content {
    let valid: Bool
    let expiresAt: Date?
    let user: UserDTO?
    
    enum CodingKeys: String, CodingKey {
        case valid
        case expiresAt = "expires_at"
        case user
    }
}

// JWTPayload conforming to JWTKit's protocol
struct JWTPayload: JWTKit.JWTPayload, Authenticatable {
    let email: String
    let username: String
    let roleId: Int
    let exp: ExpirationClaim
    let iat: IssuedAtClaim
    
    enum CodingKeys: String, CodingKey {
        case email
        case username
        case roleId = "role_id"
        case exp
        case iat
    }
    
    // JWTKit's verify method
    func verify(using algorithm: some JWTAlgorithm) throws {
        try exp.verifyNotExpired()
    }
}

extension Request {
    // Helper to get JWT key collection from storage
    var jwtKeys: JWTKeyCollection {
        guard let keys = application.storage[JWTKeyCollectionStorageKey.self] else {
            fatalError("JWTKeyCollection not configured")
        }
        return keys
    }
}

// Storage key definition (should be in configure.swift or a separate file)
struct JWTKeyCollectionStorageKey: StorageKey {
    typealias Value = JWTKeyCollection
}
