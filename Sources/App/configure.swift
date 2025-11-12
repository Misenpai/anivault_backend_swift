//
//  configure.swift
//  anivault_backend
//
//  Created by Sumit Sinha on 08/11/25.
//

import Fluent
import FluentPostgresDriver
import JWTKit
import Vapor


private struct JWTKeyCollectionStorageKey: StorageKey{
    typealias Value = JWTKeyCollection
}

public func configure(_ app: Application) async throws {
    app.http.server.configuration.hostname = "0.0.0.0"
    app.http.server.configuration.port = Environment.get("PORT").flatMap(Int.init) ?? 8080
    
    try configureDabase(app)
    
    await configureJWT(app)
    
    if let smtpHostname = Environment.get("SMTP_HOSTNAME"),
       let smtpPortString = Environment.get("SMTP_PORT"),
       let smtpPort = Int(smtpPortString),
       let smtpUsername = Environment.get("SMTP_USERNAME"),
       let smtpPassword = Environment.get("SMTP_PASSWORD"),
       let smtpFromEmail = Environment.get("SMTP_FROM_EMAIL"),
       let smtpFromName = Environment.get("SMTP_FROM_NAME") {
        
        let emailService = EmailService(
            hostname: smtpHostname,
            port: smtpPort,
            username: smtpUsername,
            password: smtpPassword,
            fromEmail: smtpFromEmail,
            fromName: smtpFromName
        )
        
        app.storage[EmailServiceKey.self] = emailService
    } else {
        app.logger.warning("SMTP not configured - email verification disabled")
    }
    
    configureMiddleware(app)

    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    try routes(app)

    app.migrations.add(CreateEmailVerifications())

    try await app.autoMigrate().wait()
}

private func configureDabase(_ app: Application) throws {
    guard let databaseURL = Environment.get("DATABASE_URL") else {
        guard let hostname = Environment.get("DB_HOST"),
              let portString = Environment.get("DB_PORT"),
              let port = Int(portString),
              let username = Environment.get("DB_USER"),
              let password = Environment.get("DB_PASSWORD"),
              let database = Environment.get("DB_NAME") else {
            throw Abort(.internalServerError, reason: "Missing required database configuration in environment variables")
        }
        
        let configuration = SQLPostgresConfiguration(
            hostname: hostname,
            port: port,
            username: username,
            password: password,
            database: database,
            tls: .prefer(try .init(configuration: .clientDefault))
        )
        
        app.databases.use(.postgres(
            configuration: configuration,
            sqlLogLevel: .debug
        ), as: .psql)
        return
    }
    
    let configuration = try SQLPostgresConfiguration(url: databaseURL)
    app.databases.use(.postgres(
        configuration: configuration,
        sqlLogLevel: .debug
    ), as: .psql)
}

private func configureJWT(_ app: Application) async {
    guard let jwtSecret = Environment.get("JWT_SECRET") else {
        fatalError("JWT_SECRET not set in environment")
    }
    
    let keys = JWTKeyCollection()
    
    await keys.add(
        hmac: .init(stringLiteral: jwtSecret),
        digestAlgorithm: .sha256
    )
    
    app.storage[JWTKeyCollectionStorageKey.self] = keys
}

private func configureMiddleware(_ app: Application) {
    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .PUT, .DELETE, .PATCH, .OPTIONS],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith]
    )
    app.middleware.use(CORSMiddleware(configuration: corsConfiguration))
    app.middleware.use(ErrorMiddleware.default(environment: app.environment))
    
    app.middleware.use(LoggingMiddleware())
}

struct EmailServiceKey: StorageKey {
    typealias Value = EmailService
}

extension Request {
    var emailService: EmailService? {
        return application.storage[EmailServiceKey.self]
    }
}
