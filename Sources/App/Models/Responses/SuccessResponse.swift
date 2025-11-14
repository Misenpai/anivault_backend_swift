import Vapor

struct SuccessResponse<T: Content>: Content {
    let success: Bool
    let message: String?
    let data: T
    let timestamp: Date

    init(message: String? = nil, data: T) {
        self.success = true
        self.message = message
        self.data = data
        self.timestamp = Date()
    }
}

struct MessageResponse: Content {
    let success: Bool
    let message: String
    let timestamp: Date

    init(message: String) {
        self.success = true
        self.message = message
        self.timestamp = Date()
    }
}

struct OptionalDataResponse<T: Content>: Content {
    let success: Bool
    let message: String?
    let data: T?
    let timestamp: Date

    init(message: String? = nil, data: T? = nil) {
        self.success = true
        self.message = message
        self.data = data
        self.timestamp = Date()
    }
}

struct CreatedResponse<T: Content>: Content {
    let success: Bool
    let message: String
    let data: T
    let resourceId: String?
    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case success
        case message
        case data
        case resourceId = "resource_id"
        case timestamp
    }

    init(message: String = "Resource created successfully", data: T, resourceId: String? = nil) {
        self.success = true
        self.message = message
        self.data = data
        self.resourceId = resourceId
        self.timestamp = Date()
    }
}

struct UpdatedResponse<T: Content>: Content {
    let success: Bool
    let message: String
    let data: T
    let timestamp: Date

    init(message: String = "Resource updated successfully", data: T) {
        self.success = true
        self.message = message
        self.data = data
        self.timestamp = Date()
    }
}

struct DeletedResponse: Content {
    let success: Bool
    let message: String
    let resourceId: String?
    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case success
        case message
        case resourceId = "resource_id"
        case timestamp
    }

    init(message: String = "Resource deleted successfully", resourceId: String? = nil) {
        self.success = true
        self.message = message
        self.resourceId = resourceId
        self.timestamp = Date()
    }
}

struct BatchOperationResponse: Content {
    let success: Bool
    let message: String
    let totalProcessed: Int
    let successful: Int
    let failed: Int
    let errors: [String]?
    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case success
        case message
        case totalProcessed = "total_processed"
        case successful
        case failed
        case errors
        case timestamp
    }

    init(
        message: String = "Batch operation completed",
        totalProcessed: Int,
        successful: Int,
        failed: Int,
        errors: [String]? = nil
    ) {
        self.success = true
        self.message = message
        self.totalProcessed = totalProcessed
        self.successful = successful
        self.failed = failed
        self.errors = errors
        self.timestamp = Date()
    }
}

struct StatusResponse: Content {
    let success: Bool
    let status: String
    let message: String?
    let details: [String: String]?
    let timestamp: Date

    init(status: String, message: String? = nil, details: [String: String]? = nil) {
        self.success = true
        self.status = status
        self.message = message
        self.details = details
        self.timestamp = Date()
    }
}

struct ResponseBuilder {

    static func success<T: Content>(_ data: T, message: String? = nil) -> SuccessResponse<T> {
        return SuccessResponse(message: message, data: data)
    }

    static func message(_ message: String) -> MessageResponse {
        return MessageResponse(message: message)
    }

    static func created<T: Content>(_ data: T, resourceId: String? = nil) -> CreatedResponse<T> {
        return CreatedResponse(data: data, resourceId: resourceId)
    }

    static func updated<T: Content>(_ data: T, message: String? = nil) -> UpdatedResponse<T> {
        return UpdatedResponse(message: message ?? "Updated successfully", data: data)
    }

    static func deleted(resourceId: String? = nil, message: String? = nil) -> DeletedResponse {
        return DeletedResponse(message: message ?? "Deleted successfully", resourceId: resourceId)
    }

    static func batch(totalProcessed: Int, successful: Int, failed: Int, errors: [String]? = nil)
        -> BatchOperationResponse
    {
        return BatchOperationResponse(
            totalProcessed: totalProcessed,
            successful: successful,
            failed: failed,
            errors: errors
        )
    }

    static func status(_ status: String, message: String? = nil, details: [String: String]? = nil)
        -> StatusResponse
    {
        return StatusResponse(status: status, message: message, details: details)
    }
}

extension Response {
    static func success<T: Content>(_ data: T, status: HTTPStatus = .ok, message: String? = nil)
        throws -> Response
    {
        let response = Response(status: status)
        try response.content.encode(SuccessResponse(message: message, data: data))
        return response
    }

    static func message(_ message: String, status: HTTPStatus = .ok) throws -> Response {
        let response = Response(status: status)
        try response.content.encode(MessageResponse(message: message))
        return response
    }

    static func created<T: Content>(_ data: T, resourceId: String? = nil) throws -> Response {
        let response = Response(status: .created)
        try response.content.encode(CreatedResponse(data: data, resourceId: resourceId))
        return response
    }

    static func updated<T: Content>(_ data: T) throws -> Response {
        let response = Response(status: .ok)
        try response.content.encode(UpdatedResponse(data: data))
        return response
    }

    static func deleted(resourceId: String? = nil) throws -> Response {
        let response = Response(status: .ok)
        try response.content.encode(DeletedResponse(resourceId: resourceId))
        return response
    }

    static func noContent() -> Response {
        return Response(status: .noContent)
    }
}

extension EventLoopFuture where Value == Response {
    func mapSuccess<T: Content>(_ data: T, message: String? = nil) -> EventLoopFuture<Response> {
        return self.map { response in
            response.status = .ok
            try? response.content.encode(SuccessResponse(message: message, data: data))
            return response
        }
    }

    func mapMessage(_ message: String) -> EventLoopFuture<Response> {
        return self.map { response in
            response.status = .ok
            try? response.content.encode(MessageResponse(message: message))
            return response
        }
    }
}
