//
//  EndpointRoleAccess.swift
//  anivault_backend
//
//  Created by Sumit Sinha on 08/11/25.
//

import Fluent
import Vapor

final class EndpointRoleAccess: Model, Content {
    static let schema = "endpoint_role_access"

    @CompositeID
    var id: IDValue?

    @Timestamp(key: "granted_at", on: .create)
    var grantedAt: Date?

    init() { }

    init(endpoint: String, method: String, roleId: Int) {
        self.id = .init(endpointID: endpoint, method: method, roleID: roleId)
    }

    init(endpoint: String, method: HTTPMethod, roleId: Int) {
        self.id = .init(endpointID: endpoint, method: method.rawValue, roleID: roleId)
    }

    final class IDValue: Fields, Hashable {
        @Parent(key: "endpoint")
        var endpoint: Endpoint

        @Field(key: "method")
        var method: String

        @Parent(key: "role_id")
        var role: Role

        init() { }

        init(endpointID: String, method: String, roleID: Int) {
            self.$endpoint.id = endpointID
            self.method = method
            self.$role.id = roleID
        }

        static func == (lhs: IDValue, rhs: IDValue) -> Bool {
            lhs.endpoint.id == rhs.endpoint.id && lhs.method == rhs.method && lhs.role.id == rhs.role.id
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(endpoint.id)
            hasher.combine(method)
            hasher.combine(role.id)
        }
    }
}

struct RoleAccessDTO: Content {
    let endpoint: String
    let method: String
    let roleId: Int
    let roleTitle: String?
    let grantedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case endpoint
        case method
        case roleId = "role_id"
        case roleTitle = "role_title"
        case grantedAt = "granted_at"
    }
}

struct AccessControlMatrixDTO: Content {
    let endpoints: [EndpointInfo]
    let roles: [RoleInfo]
    let accessMatrix: [String: [Int]]
    
    struct EndpointInfo: Content {
        let endpoint: String
        let method: String
        let description: String?
    }
    
    struct RoleInfo: Content {
        let roleId: Int
        let roleTitle: String
        
        enum CodingKeys: String, CodingKey {
            case roleId = "role_id"
            case roleTitle = "role_title"
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case endpoints
        case roles
        case accessMatrix = "access_matrix"
    }
}

struct BatchGrantAccessRequest: Content {
    let grants: [AccessGrant]
    
    struct AccessGrant: Content {
        let endpoint: String
        let method: String
        let roleIds: [Int]
        
        enum CodingKeys: String, CodingKey {
            case endpoint
            case method
            case roleIds = "role_ids"
        }
    }
}

struct BatchGrantAccessResponse: Content {
    let success: Bool
    let totalRequests: Int
    let successful: Int
    let failed: Int
    let errors: [String]?
    
    enum CodingKeys: String, CodingKey {
        case success
        case totalRequests = "total_requests"
        case successful
        case failed
        case errors
    }
}

struct RolePermissionsSummaryDTO: Content {
    let roleId: Int
    let roleTitle: String
    let totalEndpoints: Int
    let permissions: [PermissionGroup]
    
    struct PermissionGroup: Content {
        let category: String
        let endpoints: [String]
    }
    
    enum CodingKeys: String, CodingKey {
        case roleId = "role_id"
        case roleTitle = "role_title"
        case totalEndpoints = "total_endpoints"
        case permissions
    }
}

extension EndpointRoleAccess {
    func toDTO(includeRoleTitle: Bool = false) -> RoleAccessDTO {
        return RoleAccessDTO(
            endpoint: self.id?.endpoint.id ?? "",
            method: self.id?.method ?? "",
            roleId: self.id?.role.id ?? 0,
            roleTitle: includeRoleTitle ? self.id?.role.roleTitle : nil,
            grantedAt: self.grantedAt
        )
    }
    
    func matches(endpoint: String, method: String, roleId: Int) -> Bool {
        return self.id?.endpoint.id == endpoint &&
               (self.id?.method.uppercased() ?? "") == method.uppercased() &&
               self.id?.role.id == roleId
    }
}

extension EndpointRoleAccess {
    static func createForRoles(
        endpoint: String,
        method: String,
        roleIds: [Int],
        on db: Database
    ) async throws {
        for roleId in roleIds {
            let access = EndpointRoleAccess(
                endpoint: endpoint,
                method: method,
                roleId: roleId
            )
            try await access.save(on: db)
        }
    }
    
    static func deleteForRoles(
        endpoint: String,
        method: String,
        roleIds: [Int],
        on db: Database
    ) async throws {
        try await EndpointRoleAccess.query(on: db)
            .filter(\.$id.$endpoint.$id == endpoint)
            .filter(\.$id.$method == method)
            .filter(\.$id.$role.$id ~~ roleIds)
            .delete()
    }
    
    static func getRolesWithAccess(
        endpoint: String,
        method: String,
        on db: Database
    ) async throws -> [Int] {
        let accesses = try await EndpointRoleAccess.query(on: db)
            .filter(\.$id.$endpoint.$id == endpoint)
            .filter(\.$id.$method == method)
            .all()
        
        return accesses.compactMap { $0.id?.role.id }
    }
    
    static func hasAccess(
        endpoint: String,
        method: String,
        roleId: Int,
        on db: Database
    ) async throws -> Bool {
        let count = try await EndpointRoleAccess.query(on: db)
            .filter(\.$id.$endpoint.$id == endpoint)
            .filter(\.$id.$method == method)
            .filter(\.$id.$role.$id == roleId)
            .count()
        
        return count > 0
    }
    
    static func getEndpointsForRole(
        roleId: Int,
        on db: Database
    ) async throws -> [(String, String)] {
        let accesses = try await EndpointRoleAccess.query(on: db)
            .filter(\.$id.$role.$id == roleId)
            .all()
        
        return accesses.compactMap {
            guard let endpoint = $0.id?.endpoint.id, let method = $0.id?.method else { return nil }
            return (endpoint, method)
        }
    }
}

struct AccessGrantedResponse: Content {
    let success: Bool
    let message: String
    let endpoint: String
    let method: String
    let roleIds: [Int]
    
    enum CodingKeys: String, CodingKey {
        case success
        case message
        case endpoint
        case method
        case roleIds = "role_ids"
    }
}

struct AccessRevokedResponse: Content {
    let success: Bool
    let message: String
    let endpoint: String
    let method: String
    let roleIds: [Int]
    
    enum CodingKeys: String, CodingKey {
        case success
        case message
        case endpoint
        case method
        case roleIds = "role_ids"
    }
}

struct AccessControlMatrixResponse: Content {
    let success: Bool
    let data: AccessControlMatrixDTO
}
