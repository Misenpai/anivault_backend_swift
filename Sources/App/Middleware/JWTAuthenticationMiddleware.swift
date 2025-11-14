import Fluent
import JWTKit
import Vapor

struct JWTAuthenticationMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response
    {

        guard let token = request.bearerToken else {
            throw Abort(.unauthorized, reason: "Missing or invalid authorization header")
        }

        do {

            let keys = request.jwtKeys

            let payload = try await keys.verify(token, as: JWTPayload.self)

            guard let user = try await User.find(payload.email, on: request.db) else {
                throw Abort(.unauthorized, reason: "User not found")
            }

            if Constants.Features.emailVerificationRequired && !user.emailVerified {
                throw Abort(.forbidden, reason: "Email verification required")
            }

            request.auth.login(user)

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
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response
    {

        guard let token = request.bearerToken else {

            return try await next.respond(to: request)
        }

        do {

            let keys = request.jwtKeys

            let payload = try await keys.verify(token, as: JWTPayload.self)

            if let user = try await User.find(payload.email, on: request.db) {
                request.auth.login(user)
            }
        } catch {

            request.logger.debug("Optional JWT authentication failed: \(error)")
        }

        return try await next.respond(to: request)
    }
}
