import Fluent
import Vapor

final class User: Model, Content, @unchecked Sendable {
    static let schema = "users"

    @ID(custom: "email", generatedBy: .user)
    var id: String?

    @Field(key: "username")
    var username: String

    @Field(key: "password_hash")
    var passwordHash: String

    @Field(key: "email_verified")
    var emailVerified: Bool

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "last_login", on: .none)
    var lastLogin: Date?

    @OptionalField(key: "profile_image")
    var profileImage: String?

    @OptionalField(key: "bio")
    var bio: String?

    // ✅ Use @Parent instead of @Field for role_id
    @Parent(key: "role_id")
    var role: Role

    @Children(for: \.$id.$user)
    var animeStatuses: [UserAnimeStatus]

    init() {}

    init(email: String, username: String, passwordHash: String, roleId: Int = 2) {
        self.id = email
        self.username = username
        self.passwordHash = passwordHash
        self.$role.id = roleId
        self.emailVerified = false
    }

    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }
    
    // ✅ Computed property to get roleId
    var roleId: Int {
        return self.$role.id
    }
}

extension User: Authenticatable {}