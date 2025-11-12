//
//  Role.swift
//  anivault_backend
//
//  Created by Sumit Sinha on 08/11/25.
//

import Fluent
import Vapor

final class Role: Model, Content {
    static let schema = "roles"
    
    @ID(custom: "role_id")
    var id: Int?
    
    @Field(key: "role_title")
    var roleTitle: String
    
    @Children(for: \.$role)
    var users: [User]
    
    init() { }
    
    init(id: Int, roleTitle: String) {
        self.id = id
        self.roleTitle = roleTitle
    }
}
