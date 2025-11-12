import Fluent
import Vapor

struct RoleAuthorizationMiddleware: AsyncMiddleware {

    let allowedRoles: [Constants.Role]

    init(allowedRoles: [Constants.Role]) {
        self.allowedRoles = allowedRoles
    }

    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {

        guard let user = request.auth.get(User.self) else {
            throw Abort(.unauthorized, reason: "Authentication required")
        }

        guard allowedRoles.contains(where: { $0.rawValue == user.roleId }) else {
            request.logger.warning(
                "Access denied for user \(user.id ?? "unknown") with role \(user.roleId)")
            throw Abort(.forbidden, reason: "Insufficient permissions")
        }

        let endpoint = request.route?.description ?? request.url.path
        let method = request.method.string

        let hasAccess = try await checkEndpointAccess(
            endpoint: endpoint,
            method: method,
            roleId: user.roleId,
            on: request.db
        )

        guard hasAccess else {
            request.logger.warning(
                "No access to endpoint \(method) \(endpoint) for role \(user.roleId)")
            throw Abort(.forbidden, reason: "No access to this endpoint")
        }

        return try await next.respond(to: request)
    }

    private func checkEndpointAccess(
        endpoint: String,
        method: String,
        roleId: Int,
        on db: Database
    ) async throws -> Bool {

        if roleId == Constants.Role.admin.rawValue {
            return true
        }

        struct AccessCheck: Decodable {
            let hasAccess: Bool

            enum CodingKeys: String, CodingKey {
                case hasAccess = "has_access"
            }
        }

        let result = try await db.raw(
            """
                SELECT EXISTS (
                    SELECT 1 
                    FROM endpoint_role_access
                    WHERE endpoint = \(bind: endpoint)
                    AND method = \(bind: method)
                    AND role_id = \(bind: roleId)
                ) as has_access
            """
        ).first(decoding: AccessCheck.self)

        return result?.hasAccess ?? false
    }
}

struct OwnerOrAdminMiddleware: AsyncMiddleware {

    let resourceEmailKeyPath: String

    init(resourceEmailKeyPath: String = "email") {
        self.resourceEmailKeyPath = resourceEmailKeyPath
    }

    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        guard let user = request.auth.get(User.self) else {
            throw Abort(.unauthorized)
        }

        if user.roleId == Constants.Role.admin.rawValue {
            return try await next.respond(to: request)
        }

        guard let resourceEmail = request.parameters.get(resourceEmailKeyPath) else {
            throw Abort(.badRequest, reason: "Resource identifier missing")
        }

        guard user.id == resourceEmail else {
            throw Abort(.forbidden, reason: "Can only access your own resources")
        }

        return try await next.respond(to: request)
    }
}
