import Fluent
import Vapor

final class EndpointRepository {

    func find(endpoint: String, method: String, on db: any Database) async throws -> Endpoint? {
        return try await Endpoint.query(on: db)
            .filter(\.$id == endpoint)
            .filter(\.$method == method)
            .first()
    }

    func create(_ endpoint: Endpoint, on db: any Database) async throws {
        try await endpoint.save(on: db)
    }

    func update(_ endpoint: Endpoint, on db: any Database) async throws {
        try await endpoint.save(on: db)
    }

    func delete(_ endpoint: Endpoint, on db: any Database) async throws {
        try await endpoint.delete(on: db)
    }

    func all(on db: any Database) async throws -> [Endpoint] {
        return try await Endpoint.query(on: db)
            .sort(\.$id, .ascending)
            .all()
    }

    func exists(endpoint: String, method: String, on db: any Database) async throws -> Bool {
        let count = try await Endpoint.query(on: db)
            .filter(\.$id == endpoint)
            .filter(\.$method == method)
            .count()
        return count > 0
    }

    func findByMethod(_ method: String, on db: any Database) async throws -> [Endpoint] {
        return try await Endpoint.query(on: db)
            .filter(\.$method == method)
            .sort(\.$id, .ascending)
            .all()
    }

    func searchByPath(_ query: String, on db: any Database) async throws -> [Endpoint] {
        return try await Endpoint.query(on: db)
            .filter(\.$id =~ query)
            .sort(\.$id, .ascending)
            .all()
    }

    func findWithRoleAccess(endpoint: String, method: String, on db: any Database) async throws
        -> Endpoint?
    {
        return try await Endpoint.query(on: db)
            .filter(\.$id == endpoint)
            .filter(\.$method == method)
            .with(\.$roleAccess)
            .first()
    }

    func allWithRoleAccess(on db: any Database) async throws -> [Endpoint] {
        return try await Endpoint.query(on: db)
            .with(\.$roleAccess)
            .sort(\.$id, .ascending)
            .all()
    }

    func hasAccess(endpoint: String, method: String, roleId: Int, on db: any Database) async throws
        -> Bool
    {
        let count = try await EndpointRoleAccess.query(on: db)
            .filter(\.$id.$endpoint.$id == endpoint)
            .filter(\.$id.$method == method)
            .filter(\.$id.$role.$id == roleId)
            .count()
        return count > 0
    }

    func grantAccess(endpoint: String, method: String, roleId: Int, on db: any Database) async throws {
        let access = EndpointRoleAccess(endpoint: endpoint, method: method, roleId: roleId)
        try await access.save(on: db)
    }

    func revokeAccess(endpoint: String, method: String, roleId: Int, on db: any Database) async throws {
        try await EndpointRoleAccess.query(on: db)
            .filter(\.$id.$endpoint.$id == endpoint)
            .filter(\.$id.$method == method)
            .filter(\.$id.$role.$id == roleId)
            .delete()
    }

    func getRolesWithAccess(endpoint: String, method: String, on db: any Database) async throws -> [Int]
    {
        let accesses = try await EndpointRoleAccess.query(on: db)
            .filter(\.$id.$endpoint.$id == endpoint)
            .filter(\.$id.$method == method)
            .all()
        return accesses.map { $0.id!.role.id! }
    }

    func getEndpointsForRole(_ roleId: Int, on db: any Database) async throws -> [(String, String)] {
        let accesses = try await EndpointRoleAccess.query(on: db)
            .filter(\.$id.$role.$id == roleId)
            .all()
        return accesses.map { ($0.id!.endpoint.id!, $0.id!.method) }
    }

    func count(on db: any Database) async throws -> Int {
        return try await Endpoint.query(on: db).count()
    }
}
