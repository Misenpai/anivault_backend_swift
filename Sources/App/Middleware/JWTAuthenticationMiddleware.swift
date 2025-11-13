import Fluent
import JWTKit
import Vapor

struct JWTAuthenticationMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        // Get bearer token
        guard let token = request.bearerToken else {
            throw Abort(.unauthorized, reason: "Missing or invalid authorization header")
        }
        
        do {
            // Get JWT key collection from app storage
            let keys = request.jwtKeys
            
            // Verify and decode token
            let payload = try await keys.verify(token, as: JWTPayload.self)
            
            // Find user in database
            guard let user = try await User.find(payload.email, on: request.db) else {
                throw Abort(.unauthorized, reason: "User not found")
            }
            
            // Check email verification if required
            if Constants.Features.emailVerificationRequired && !user.emailVerified {
                throw Abort(.forbidden, reason: "Email verification required")
            }
            
            // Login user to request
            request.auth.login(user)
            
            // Add user metadata to logs
            request.logger[metadataKey: "user_email"] = .string(user.id ?? "unknown")
            request.logger[metadataKey: "user_role"] = .string("\(user.roleId)")
            
            return try await next.respond(to: request)
            
        } catch let jwtError as JWTError {
            request.logger.error("JWT verification failed: \(jwtError)")
            throw Abort(.unauthorized, reason: "Invalid or expired token")
        } catch {
            request.logger.error("Authentication error: \(error)")
            throw Abort(.unauthorized, reason: "Authentication failed")
        }
    }
}

struct OptionalJWTAuthenticationMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        // Get bearer token (optional)
        guard let token = request.bearerToken else {
            // No token, continue without authentication
            return try await next.respond(to: request)
        }
        
        do {
            // Get JWT key collection from app storage
            let keys = request.jwtKeys
            
            // Verify and decode token
            let payload = try await keys.verify(token, as: JWTPayload.self)
            
            // Try to find user
            if let user = try await User.find(payload.email, on: request.db) {
                request.auth.login(user)
            }
        } catch {
            // Log but don't fail - this is optional authentication
            request.logger.debug("Optional JWT authentication failed: \(error)")
        }
        
        return try await next.respond(to: request)
    }
}
