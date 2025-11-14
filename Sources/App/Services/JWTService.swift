import JWTKit
import Vapor
import Fluent

final class JWTService {
    private let jwtSecret: String
    private let jwtExpiration: TimeInterval
    
    init(jwtSecret: String? = nil, jwtExpiration: TimeInterval? = nil) {
        self.jwtSecret = jwtSecret ?? Environment.get("JWT_SECRET") ?? "default-secret-change-in-production"
        self.jwtExpiration = jwtExpiration ?? TimeInterval(Environment.get("JWT_EXPIRATION").flatMap(Int.init) ?? 604800)
    }
    
    // Create a key collection for signing/verifying
    private func createKeyCollection() async -> JWTKeyCollection {
        let keys = JWTKeyCollection()
        await keys.add(hmac: HMACKey(from: jwtSecret), digestAlgorithm: .sha256)
        return keys
    }
    
    func generateToken(for user: User) async throws -> String {
        let expirationDate = Date().addingTimeInterval(jwtExpiration)
        
        let payload = JWTPayload(
            email: user.id ?? "",
            username: user.username,
            roleId: user.roleId,
            exp: ExpirationClaim(value: expirationDate),
            iat: IssuedAtClaim(value: Date())
        )
        
        let keys = await createKeyCollection()
        return try await keys.sign(payload)
    }
    
    func verifyToken(_ token: String) async throws -> JWTPayload {
        let keys = await createKeyCollection()
        let payload = try await keys.verify(token, as: JWTPayload.self)
        return payload
    }
    
    func refreshToken(from oldToken: String, for user: User) async throws -> String {
        // Verify the old token first
        _ = try await verifyToken(oldToken)
        
        // Generate new token
        return try await generateToken(for: user)
    }
    
    func decodeWithoutVerification(_ token: String) async throws -> JWTPayload {
        let keys = await createKeyCollection()
        return try await keys.unverified(token, as: JWTPayload.self)
    }
    
    func getExpirationDate(from token: String) async throws -> Date {
        let payload = try await verifyToken(token)
        return payload.exp.value
    }
    
    func isTokenExpired(_ token: String) async -> Bool {
        do {
            _ = try await verifyToken(token)
            return false
        } catch {
            return true
        }
    }
    
    func getUserEmail(from token: String) async throws -> String {
        let payload = try await verifyToken(token)
        return payload.email
    }
    
    func getUserRole(from token: String) async throws -> Int {
        let payload = try await verifyToken(token)
        return payload.roleId
    }
    
    func getTokenMetadata(from token: String) async throws -> TokenMetadata {
        let payload = try await verifyToken(token)
        
        return TokenMetadata(
            email: payload.email,
            username: payload.username,
            roleId: payload.roleId,
            issuedAt: payload.iat.value,
            expiresAt: payload.exp.value,
            isExpired: false
        )
    }
    
    func generateTokens(for users: [User]) async throws -> [String: String] {
        var tokens: [String: String] = [:]
        
        for user in users {
            if let email = user.id {
                let token = try await generateToken(for: user)
                tokens[email] = token
            }
        }
        
        return tokens
    }
    
    func isTokenBlacklisted(_ token: String, on db: Database) async throws -> Bool {
        // TODO: Implement token blacklisting
        return false
    }
    
    func blacklistToken(_ token: String, on db: Database) async throws {
        // TODO: Implement token blacklisting
    }
}

struct TokenMetadata: Content {
    let email: String
    let username: String
    let roleId: Int
    let issuedAt: Date
    let expiresAt: Date
    let isExpired: Bool
    
    enum CodingKeys: String, CodingKey {
        case email
        case username
        case roleId = "role_id"
        case issuedAt = "issued_at"
        case expiresAt = "expires_at"
        case isExpired = "is_expired"
    }
}

enum JWTServiceError: Error, LocalizedError {
    case invalidToken
    case expiredToken
    case missingClaims
    case invalidSignature
    case tokenBlacklisted
    
    var errorDescription: String? {
        switch self {
        case .invalidToken:
            return "Invalid token format"
        case .expiredToken:
            return "Token has expired"
        case .missingClaims:
            return "Token is missing required claims"
        case .invalidSignature:
            return "Token signature is invalid"
        case .tokenBlacklisted:
            return "Token has been revoked"
        }
    }
}

extension JWTPayload {
    var isExpired: Bool {
        return exp.value < Date()
    }
    
    var timeUntilExpiration: TimeInterval {
        return exp.value.timeIntervalSince(Date())
    }
    
    var age: TimeInterval {
        return Date().timeIntervalSince(iat.value)
    }
}