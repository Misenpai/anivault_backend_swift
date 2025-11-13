import Fluent
import Vapor

final class Role: Model, Content, @unchecked Sendable {
    static let schema = "roles"
    
    // ✅ FIX: Use @ID with custom key
    @ID(custom: "role_id", generatedBy: .database)
    var id: Int?
    
    @Field(key: "role_title")
    var roleTitle: String
    
    @Children(for: \.$roleId)
    var users: [User]
    
    init() { }
    
    init(id: Int? = nil, roleTitle: String) {
        self.id = id
        self.roleTitle = roleTitle
    }
}