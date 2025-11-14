import Vapor

struct ErrorResponse: Content {
    let success: Bool
    let error: ErrorDetail

    struct ErrorDetail: Content {
        let code: String
        let message: String
        let details: String?
        let timestamp: Date
        let path: String?

        init(code: String, message: String, details: String? = nil, path: String? = nil) {
            self.code = code
            self.message = message
            self.details = details
            self.timestamp = Date()
            self.path = path
        }
    }

    init(code: String, message: String, details: String? = nil, path: String? = nil) {
        self.success = false
        self.error = ErrorDetail(code: code, message: message, details: details, path: path)
    }
}

struct ValidationErrorResponse: Content {
    let success: Bool
    let error: String
    let validationErrors: [ValidationError]

    struct ValidationError: Content {
        let field: String
        let message: String
        let value: String?

        init(field: String, message: String, value: String? = nil) {
            self.field = field
            self.message = message
            self.value = value
        }
    }

    enum CodingKeys: String, CodingKey {
        case success
        case error
        case validationErrors = "validation_errors"
    }

    init(message: String = "Validation failed", errors: [ValidationError]) {
        self.success = false
        self.error = message
        self.validationErrors = errors
    }
}

struct AuthErrorResponse: Content {
    let success: Bool
    let error: String
    let code: String
    let requiredAction: String?

    enum CodingKeys: String, CodingKey {
        case success
        case error
        case code
        case requiredAction = "required_action"
    }

    init(error: String, code: String, requiredAction: String? = nil) {
        self.success = false
        self.error = error
        self.code = code
        self.requiredAction = requiredAction
    }
}

struct NotFoundErrorResponse: Content {
    let success: Bool
    let error: String
    let resource: String
    let identifier: String?

    init(resource: String, identifier: String? = nil) {
        self.success = false
        self.error = "\(resource) not found"
        self.resource = resource
        self.identifier = identifier
    }
}

struct ConflictErrorResponse: Content {
    let success: Bool
    let error: String
    let conflictingField: String
    let value: String?

    enum CodingKeys: String, CodingKey {
        case success
        case error
        case conflictingField = "conflicting_field"
        case value
    }

    init(field: String, value: String? = nil) {
        self.success = false
        self.error = "\(field) already exists"
        self.conflictingField = field
        self.value = value
    }
}

struct RateLimitErrorResponse: Content {
    let success: Bool
    let error: String
    let retryAfter: Int
    let limit: Int
    let remaining: Int

    enum CodingKeys: String, CodingKey {
        case success
        case error
        case retryAfter = "retry_after"
        case limit
        case remaining
    }

    init(retryAfter: Int, limit: Int, remaining: Int = 0) {
        self.success = false
        self.error = "Rate limit exceeded"
        self.retryAfter = retryAfter
        self.limit = limit
        self.remaining = remaining
    }
}

enum APIErrorCode: String {
    case invalidCredentials = "AUTH_1001"
    case tokenExpired = "AUTH_1002"
    case tokenInvalid = "AUTH_1003"
    case unauthorized = "AUTH_1004"
    case emailNotVerified = "AUTH_1005"
    case accountLocked = "AUTH_1006"
    case validationFailed = "VALIDATION_2001"
    case invalidEmail = "VALIDATION_2002"
    case invalidPassword = "VALIDATION_2003"
    case invalidUsername = "VALIDATION_2004"
    case missingField = "VALIDATION_2005"
    case notFound = "RESOURCE_3001"
    case alreadyExists = "RESOURCE_3002"
    case forbidden = "RESOURCE_3003"
    case gone = "RESOURCE_3004"
    case databaseError = "DATABASE_4001"
    case connectionFailed = "DATABASE_4002"
    case queryFailed = "DATABASE_4003"
    case externalServiceError = "EXTERNAL_5001"
    case emailSendFailed = "EXTERNAL_5002"
    case jikanAPIError = "EXTERNAL_5003"
    case rateLimitExceeded = "RATE_6001"
    case internalError = "SERVER_9001"
    case notImplemented = "SERVER_9002"
    case serviceUnavailable = "SERVER_9003"
}

extension Abort {
    static func custom(_ status: HTTPStatus, code: APIErrorCode, reason: String) -> Abort {
        return Abort(status, reason: reason, identifier: code.rawValue)
    }

    static func invalidCredentials() -> Abort {
        return .custom(
            .unauthorized, code: .invalidCredentials, reason: "Invalid email or password")
    }

    static func tokenExpired() -> Abort {
        return .custom(.unauthorized, code: .tokenExpired, reason: "Token has expired")
    }

    static func emailNotVerified() -> Abort {
        return .custom(
            .forbidden, code: .emailNotVerified, reason: "Please verify your email address")
    }

    static func emailAlreadyExists() -> Abort {
        return .custom(.conflict, code: .alreadyExists, reason: "Email already exists")
    }

    static func usernameAlreadyExists() -> Abort {
        return .custom(.conflict, code: .alreadyExists, reason: "Username already taken")
    }

    static func userNotFound() -> Abort {
        return .custom(.notFound, code: .notFound, reason: "User not found")
    }

    static func animeNotFound() -> Abort {
        return .custom(.notFound, code: .notFound, reason: "Anime not found in your list")
    }
}

struct CustomErrorMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        do {
            return try await next.respond(to: request)
        } catch let error as Abort {
            return try await handleAbortError(error, request: request)
        } catch let error as DecodingError {
            return try await handleDecodingError(error, request: request)
        } catch {
            return try await handleUnknownError(error, request: request)
        }
    }

    private func handleAbortError(_ error: Abort, request: Request) async throws -> Response {
        let response = Response(status: error.status)

        let errorResponse = ErrorResponse(
            code: error.identifier,
            message: error.reason,
            path: request.url.path
        )

        try response.content.encode(errorResponse)
        return response
    }

    private func handleDecodingError(_ error: DecodingError, request: Request) async throws -> Response {
        let response = Response(status: .badRequest)

        var validationErrors: [ValidationErrorResponse.ValidationError] = []
        
        switch error {
        case .keyNotFound(let key, _):
            validationErrors.append(
                ValidationErrorResponse.ValidationError(
                    field: key.stringValue,
                    message: "Missing required field"
                )
            )
        case .valueNotFound(_, let context):
            validationErrors.append(
                ValidationErrorResponse.ValidationError(
                    field: context.codingPath.last?.stringValue ?? "unknown",
                    message: "Value not found"
                )
            )
        case .typeMismatch(_, let context):
            validationErrors.append(
                ValidationErrorResponse.ValidationError(
                    field: context.codingPath.last?.stringValue ?? "unknown",
                    message: "Invalid type"
                )
            )
        case .dataCorrupted(let context):
            validationErrors.append(
                ValidationErrorResponse.ValidationError(
                    field: context.codingPath.last?.stringValue ?? "unknown",
                    message: "Data corrupted"
                )
            )
        @unknown default:
            validationErrors.append(
                ValidationErrorResponse.ValidationError(
                    field: "unknown",
                    message: "Decoding error"
                )
            )
        }

        let errorResponse = ValidationErrorResponse(errors: validationErrors)
        try response.content.encode(errorResponse)
        return response
    }

    private func handleUnknownError(_ error: any Error, request: Request) async throws -> Response {
        request.logger.error("Unhandled error: \(error)")

        let response = Response(status: .internalServerError)

        let errorResponse = ErrorResponse(
            code: APIErrorCode.internalError.rawValue,
            message: "An unexpected error occurred",
            details: request.application.environment == .development
                ? error.localizedDescription : nil,
            path: request.url.path
        )

        try response.content.encode(errorResponse)
        return response
    }
}