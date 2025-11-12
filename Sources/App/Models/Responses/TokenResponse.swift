//
//  TokenResponse.swift
//  anivault_backend
//
//  Created by Sumit Sinha on 08/11/25.
//

import Vapor

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

struct JWTPayload: Content, Authenticatable {
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
    
    func verify(using signer: JWTSigner) throws {
        try exp.verifyNotExpired()
    }
}

extension Request {
    var bearerToken: String? {
        guard let authorization = headers[.authorization].first,
              authorization.hasPrefix("Bearer ") else {
            return nil
        }
        return String(authorization.dropFirst(7))
    }
}
