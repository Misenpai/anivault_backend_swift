//
//  Endpoint.swift
//  anivault_backend
//
//  Created by Sumit Sinha on 08/11/25.
//

import Fluent
import Vapor

final class Endpoint: Model, Content {
    static let schema = "endpoints"
    
    @ID(custom: "endpoint", generatedBy: .user)
    var id: String?
    
    @Field(key: "method")
    var method: String
    
    @Field(key: "description")
    var description: String?
    
    @Children(for: \.$id.$endpoint)
    var roleAccess: [EndpointRoleAccess]
    
    init() { }
    
    init(id: String, method: String, description: String? = nil) {
        self.id = id
        self.method = method
        self.description = description
    }
}
