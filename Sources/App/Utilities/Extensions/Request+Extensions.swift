import Vapor

extension Request {

    var bearerToken: String? {
        guard let authorization = headers[.authorization].first,
            authorization.hasPrefix("Bearer ")
        else {
            return nil
        }
        return String(authorization.dropFirst(7)).trimmingCharacters(in: .whitespaces)
    }

    var paginationRequest: PaginationRequest {
        let page = query[Int.self, at: "page"] ?? Constants.Pagination.defaultPage
        let limit = query[Int.self, at: "limit"] ?? Constants.Pagination.defaultLimit
        return PaginationRequest(page: page, limit: limit)
    }

    var cursorPaginationRequest: CursorPaginationRequest {
        let cursor = query[String.self, at: "cursor"]
        let limit = query[Int.self, at: "limit"] ?? CursorPaginationRequest.defaultLimit
        return CursorPaginationRequest(cursor: cursor, limit: limit)
    }

    var userEmail: String? {
        return auth.get(User.self)?.id
    }

    var currentUser: User? {
        return auth.get(User.self)
    }

    func requireUser() throws -> User {
        guard let user = currentUser else {
            throw Abort(.unauthorized, reason: "Authentication required")
        }
        return user
    }

    func hasRole(_ role: Constants.Role) -> Bool {
        guard let user = currentUser else { return false }
        return user.roleId == role.rawValue
    }

    var isAdmin: Bool {
        return hasRole(.admin)
    }

    func query<T: LosslessStringConvertible & Decodable>(_ key: String, default defaultValue: T)
        -> T
    {
        return query[T.self, at: key] ?? defaultValue
    }

    func requireQuery<T: LosslessStringConvertible & Decodable>(_ key: String) throws -> T {
        guard let value = query[T.self, at: key] else {
            throw Abort(.badRequest, reason: "Missing required query parameter: \(key)")
        }
        return value
    }

    func requireParameter<T: LosslessStringConvertible>(_ key: String) throws -> T {
        guard let value = parameters.get(key, as: T.self) else {
            throw Abort(.badRequest, reason: "Missing required parameter: \(key)")
        }
        return value
    }

    var emailService: ResendEmailService? {
        return application.storage[ResendEmailServiceKey.self]
    }

    var clientIP: String? {
        if let forwardedFor = headers.first(name: "X-Forwarded-For") {
            return forwardedFor.split(separator: ",").first.map(String.init)?.trimmingCharacters(
                in: .whitespaces)
        }

        if let realIP = headers.first(name: "X-Real-IP") {
            return realIP
        }

        return remoteAddress?.ipAddress
    }

    var userAgent: String? {
        return headers.first(name: .userAgent)
    }

    var requestID: String {
        if let existing = headers.first(name: "X-Request-ID") {
            return existing
        }
        let id = UUID().uuidString
        headers.replaceOrAdd(name: "X-Request-ID", value: id)
        return id
    }

    var isJSON: Bool {
        return headers.contentType == .json
    }

    var isFormData: Bool {
        return headers.contentType == .formData
    }

    func validateAndDecode<T: Content & Validatable>(_ type: T.Type) throws -> T {
        try T.validate(content: self)
        return try content.decode(T.self)
    }

    func success<T: Content>(_ data: T, status: HTTPStatus = .ok) throws -> Response {
        return try Response.success(data, status: status)
    }

    func message(_ message: String, status: HTTPStatus = .ok) throws -> Response {
        return try Response.message(message, status: status)
    }

    func error(_ message: String, status: HTTPStatus = .badRequest) -> Response {
        let response = Response(status: status)
        try? response.content.encode(
            ErrorResponse(
                code: "ERROR",
                message: message
            ))
        return response
    }
}

// ✅ Keep the key definition here
struct ResendEmailServiceKey: StorageKey {
    typealias Value = ResendEmailService
}