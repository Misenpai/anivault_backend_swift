import Fluent
import Vapor

struct RoleAuthorizationMiddleware: AsyncMiddleware {
    let allowedRoles: [Constants.Role]

    init(allowedRoles: [Constants.Role]) {
        self.allowedRoles = allowedRoles
    }

    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        guard let user = request.auth.get(User.self) else {
            throw Abort(.unauthorized, reason: "Authentication required")
        }

        guard allowedRoles.contains(where: { $0.rawValue == user.role.id }) else {
            request.logger.warning("Access denied for user \(user.id ?? "unknown") with role \(user.roleId)")
            throw Abort(.forbidden, reason: "Insufficient permissions")
        }

        let endpoint = request.route?.description ?? request.url.path
        let method = request.method.rawValue

        let hasAccess = try await checkEndpointAccess(
            endpoint: endpoint,
            method: method,
            roleId: user.roleId,
            on: request.db
        )

        guard hasAccess else {
            request.logger.warning("No access to endpoint \(method) \(endpoint) for role \(user.roleId)")
            throw Abort(.forbidden, reason: "No access to this endpoint")
        }

        return try await next.respond(to: request)
    }

    private func checkEndpointAccess(
        endpoint: String,
        method: String,
        roleId: Int,
        on db: any Database
    ) async throws -> Bool {
        // Admin role_id=1 bypasses all checks
        if roleId == Constants.Role.admin.rawValue {
            return true
        }

        // ✅ FIX: Use proper query instead of raw SQL
        let count = try await EndpointRoleAccess.query(on: db)
            .filter(\.$id.$endpoint.$id == endpoint)
            .filter(\.$id.$method == method)
            .filter(\.$id.$role.$id == roleId)
            .count()
        
        return count > 0
    }
}