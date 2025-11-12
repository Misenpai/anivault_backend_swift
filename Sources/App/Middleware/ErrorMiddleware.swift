import Vapor

struct CustomErrorMiddleware: AsyncMiddleware {

    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        do {
            return try await next.respond(to: request)
        } catch {
            return try await handleError(error, for: request)
        }
    }

    private func handleError(_ error: Error, for request: Request) async throws -> Response {

        request.logger.error("Error: \(error)")

        if let abort = error as? Abort {
            return try await handleAbortError(abort, for: request)
        } else if let validationError = error as? ValidationError {
            return try await handleValidationError(validationError, for: request)
        } else if let decodingError = error as? DecodingError {
            return try await handleDecodingError(decodingError, for: request)
        } else {
            return try await handleUnknownError(error, for: request)
        }
    }

    private func handleAbortError(_ abort: Abort, for request: Request) async throws -> Response {
        let response = Response(status: abort.status)

        let errorResponse = ErrorResponse(
            code: abort.identifier ?? "ABORT_\(abort.status.code)",
            message: abort.reason,
            path: request.url.path
        )

        try response.content.encode(errorResponse)
        return response
    }

    private func handleValidationError(_ error: ValidationError, for request: Request) async throws
        -> Response
    {
        let response = Response(status: .badRequest)

        let validationErrors = error.failures.map { failure in
            ValidationErrorResponse.ValidationError(
                field: failure.key.stringValue,
                message: failure.result.failureDescription ?? "Invalid value"
            )
        }

        let errorResponse = ValidationErrorResponse(errors: validationErrors)
        try response.content.encode(errorResponse)
        return response
    }

    private func handleDecodingError(_ error: DecodingError, for request: Request) async throws
        -> Response
    {
        let response = Response(status: .badRequest)

        var message = "Invalid request body"

        switch error {
        case .keyNotFound(let key, _):
            message = "Missing required field: \(key.stringValue)"
        case .typeMismatch(_, let context):
            message =
                "Type mismatch at: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
        case .valueNotFound(_, let context):
            message =
                "Value not found at: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
        case .dataCorrupted(let context):
            message = "Data corrupted: \(context.debugDescription)"
        @unknown default:
            message = "Decoding error"
        }

        let errorResponse = ErrorResponse(
            code: "DECODING_ERROR",
            message: message,
            path: request.url.path
        )

        try response.content.encode(errorResponse)
        return response
    }

    private func handleUnknownError(_ error: Error, for request: Request) async throws -> Response {
        request.logger.error("Unhandled error: \(error)")

        let response = Response(status: .internalServerError)

        let errorResponse = ErrorResponse(
            code: "INTERNAL_ERROR",
            message: Constants.App.isDevelopment
                ? error.localizedDescription : "An unexpected error occurred",
            details: Constants.App.isDevelopment ? "\(error)" : nil,
            path: request.url.path
        )

        try response.content.encode(errorResponse)
        return response
    }
}
