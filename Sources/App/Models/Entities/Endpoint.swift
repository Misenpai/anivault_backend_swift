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
    
    @Field(key: "description")
    var description: String?
    
    init() { }
    
    init(id: String, description: String? = nil) {
        self.id = id
        self.description = description
    }
}
