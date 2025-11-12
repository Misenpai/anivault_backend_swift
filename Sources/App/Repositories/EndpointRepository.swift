//
//  EndpointRepository.swift
//  anivault_backend
//
//  Created by Sumit Sinha on 11/11/25.
//

import Fluent
import Vapor

final class EndpointRepository {
    
    /// Find endpoint by endpoint path and method
    func find(endpoint: String, method: String, on db: Database) async throws -> Endpoint? {
        return try await Endpoint.query(on: db)
            .filter(\.$endpoint == endpoint)
            .filter(\.$method == method)
            .first()
    }
    
    /// Create new endpoint
    func create(_ endpoint: Endpoint, on db: Database) async throws {
        try await endpoint.save(on: db)
    }
    
    /// Update endpoint
    func update(_ endpoint: Endpoint, on db: Database) async throws {
        try await endpoint.save(on: db)
    }
    
    /// Delete endpoint
    func delete(_ endpoint: Endpoint, on db: Database) async throws {
        try await endpoint.delete(on: db)
    }
    
    /// Get all endpoints
    func all(on db: Database) async throws -> [Endpoint] {
        return try await Endpoint.query(on: db)
            .sort(\.$endpoint, .ascending)
            .all()
    }
    
    /// Check if endpoint exists
    func exists(endpoint: String, method: String, on db: Database) async throws -> Bool {
        let count = try await Endpoint.query(on: db)
            .filter(\.$endpoint == endpoint)
            .filter(\.$method == method)
            .count()
        return count > 0
    }
    
    /// Get endpoints by method
    func findByMethod(_ method: String, on db: Database) async throws -> [Endpoint] {
        return try await Endpoint.query(on: db)
            .filter(\.$method == method)
            .sort(\.$endpoint, .ascending)
            .all()
    }
    
    /// Search endpoints by path
    func searchByPath(_ query: String, on db: Database) async throws -> [Endpoint] {
        return try await Endpoint.query(on: db)
            .filter(\.$endpoint =~ query)
            .sort(\.$endpoint, .ascending)
            .all()
    }
    
    /// Get endpoints with role access
    func findWithRoleAccess(endpoint: String, method: String, on db: Database) async throws -> Endpoint? {
        return try await Endpoint.query(on: db)
            .filter(\.$endpoint == endpoint)
            .filter(\.$method == method)
            .with(\.$roleAccess)
            .first()
    }
    
    /// Get all endpoints with their role access
    func allWithRoleAccess(on db: Database) async throws -> [Endpoint] {
        return try await Endpoint.query(on: db)
            .with(\.$roleAccess)
            .sort(\.$endpoint, .ascending)
            .all()
    }
    
    /// Check if role has access to endpoint
    func hasAccess(endpoint: String, method: String, roleId: Int, on db: Database) async throws -> Bool {
        let count = try await EndpointRoleAccess.query(on: db)
            .filter(\.$endpoint == endpoint)
            .filter(\.$method == method)
            .filter(\.$roleId == roleId)
            .count()
        return count > 0
    }
    
    /// Grant role access to endpoint
    func grantAccess(endpoint: String, method: String, roleId: Int, on db: Database) async throws {
        let access = EndpointRoleAccess(endpoint: endpoint, method: method, roleId: roleId)
        try await access.save(on: db)
    }
    
    /// Revoke role access from endpoint
    func revokeAccess(endpoint: String, method: String, roleId: Int, on db: Database) async throws {
        try await EndpointRoleAccess.query(on: db)
            .filter(\.$endpoint == endpoint)
            .filter(\.$method == method)
            .filter(\.$roleId == roleId)
            .delete()
    }
    
    /// Get all roles that have access to endpoint
    func getRolesWithAccess(endpoint: String, method: String, on db: Database) async throws -> [Int] {
        let accesses = try await EndpointRoleAccess.query(on: db)
            .filter(\.$endpoint == endpoint)
            .filter(\.$method == method)
            .all()
        return accesses.map { $0.roleId }
    }
    
    /// Get all endpoints accessible by role
    func getEndpointsForRole(_ roleId: Int, on db: Database) async throws -> [(String, String)] {
        let accesses = try await EndpointRoleAccess.query(on: db)
            .filter(\.$roleId == roleId)
            .all()
        return accesses.map { ($0.endpoint, $0.method) }
    }
    
    /// Count total endpoints
    func count(on db: Database) async throws -> Int {
        return try await Endpoint.query(on: db).count()
    }
}

// MARK: - Endpoint Model
final class Endpoint: Model, Content {
    static let schema = "endpoints"
    
    @ID(custom: .id)
    var id: Int?
    
    @Field(key: "endpoint")
    var endpoint: String
    
    @Field(key: "method")
    var method: String
    
    @Field(key: "description")
    var description: String?
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Children(for: \.$endpoint)
    var roleAccess: [EndpointRoleAccess]
    
    init() { }
    
    init(endpoint: String, method: String, description: String? = nil) {
        self.endpoint = endpoint
        self.method = method
        self.description = description
    }
}

// MARK: - EndpointRoleAccess Model
final class EndpointRoleAccess: Model, Content {
    static let schema = "endpoint_role_access"
    
    @ID(custom: .id)
    var id: Int?
    
    @Field(key: "endpoint")
    var endpoint: String
    
    @Field(key: "method")
    var method: String
    
    @Field(key: "role_id")
    var roleId: Int
    
    @Timestamp(key: "granted_at", on: .create)
    var grantedAt: Date?
    
    init() { }
    
    init(endpoint: String, method: String, roleId: Int) {
        self.endpoint = endpoint
        self.method = method
        self.roleId = roleId
    }
}
