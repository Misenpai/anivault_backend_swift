// Sources/App/Services/JWTService.swift
import JWTKit
import Vapor
import Fluent

final class JWTService {
    private let jwtSecret: String
    
    init(jwtSecret: String? = nil) {
        self.jwtSecret = jwtSecret ?? Environment.get("JWT_SECRET") ?? "default-secret-change-in-production"
    }
    
    private func createKeyCollection() async -> JWTKeyCollection {
        let keys = JWTKeyCollection()
        await keys.add(hmac: HMACKey(from: jwtSecret), digestAlgorithm: .sha256)
        return keys
    }
    
    func generateToken(for user: User, expiration: TimeInterval = 3600) async throws -> String {
        let expirationDate = Date().addingTimeInterval(expiration)
        
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
}