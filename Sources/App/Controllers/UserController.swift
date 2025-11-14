import Fluent
import Vapor

final class UserController: RouteCollection, @unchecked Sendable {
    private let userService: UserService

    init(userService: UserService) {
        self.userService = userService
    }

    func boot(routes: any RoutesBuilder) throws {
        let users = routes.grouped("users")
            .grouped(JWTAuthenticationMiddleware())

        let adminRoutes = users.grouped(RoleAuthorizationMiddleware(allowedRoles: [.admin]))
        adminRoutes.get(use: getAllUsers)
        adminRoutes.delete(":email", use: deleteUser)

        users.get(":email", use: getUser)
        users.put(":email", use: updateUser)
        users.patch(":email", use: patchUser)

        users.get("page", ":page", "limit", ":limit", use: getUsersPaginated)
    }

    private func getAllUsers(req: Request) async throws -> [UserDTO] {
        try await userService.getAllUsers(on: req)
    }

    private func getUser(req: Request) async throws -> UserDTO {
        guard let email = req.parameters.get("email") else {
            throw Abort(.badRequest, reason: "Email parameter missing")
        }

        let requestingUser = try req.auth.require(User.self)
        guard requestingUser.roleId == 1 || requestingUser.id == email else {
            throw Abort(.forbidden)
        }

        return try await userService.getUser(email: email, on: req)
    }

    private func updateUser(req: Request) async throws -> UserDTO {
        guard let email = req.parameters.get("email") else {
            throw Abort(.badRequest, reason: "Email parameter missing")
        }

        let requestingUser = try req.auth.require(User.self)
        guard requestingUser.roleId == 1 || requestingUser.id == email else {
            throw Abort(.forbidden)
        }

        let updateRequest = try req.content.decode(UserPatchRequest.self)
        return try await userService.updateUser(email: email, data: updateRequest, on: req)
    }

    private func patchUser(req: Request) async throws -> UserDTO {
        guard let email = req.parameters.get("email") else {
            throw Abort(.badRequest, reason: "Email parameter missing")
        }

        let requestingUser = try req.auth.require(User.self)
        guard requestingUser.roleId == 1 || requestingUser.id == email else {
            throw Abort(.forbidden)
        }

        let patchData = try req.content.decode([String: String].self)
        return try await userService.patchUser(email: email, data: patchData, on: req)
    }

    private func deleteUser(req: Request) async throws -> HTTPStatus {
        guard let email = req.parameters.get("email") else {
            throw Abort(.badRequest, reason: "Email parameter missing")
        }

        try await userService.deleteUser(email: email, on: req)
        return .noContent
    }

    private func getUsersPaginated(req: Request) async throws -> Page<UserDTO> {
        guard let page = req.parameters.get("page", as: Int.self),
            let limit = req.parameters.get("limit", as: Int.self)
        else {
            throw Abort(.badRequest, reason: "Invalid pagination parameters")
        }

        return try await userService.getUsersPaginated(page: page, limit: limit, on: req)
    }
}
