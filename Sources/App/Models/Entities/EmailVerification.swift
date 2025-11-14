import Fluent
import Vapor

final class EmailVerification: Model, Content, @unchecked Sendable {
    static let schema = "email_verifications"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "email")
    var email: String

    @Field(key: "code")
    var code: String

    @Timestamp(key: "expires_at", on: .none)
    var expiresAt: Date?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    init() {}

    init(email: String, code: String, expiresAt: Date) {
        self.email = email
        self.code = code
        self.expiresAt = expiresAt
    }
}
