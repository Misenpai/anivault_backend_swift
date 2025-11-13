//
//  main.swift
//  anivault_backend
//
//  Created by Sumit Sinha on 08/11/25.
//

import App
import Vapor

@main
struct Main {
    static func main() async throws {
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)
        
        let app = try await Application.make(env)
        defer { app.shutdown() }
        
        try await configure(app)
        try await app.execute()
    }
}