import DotEnv
import Fluent
import FluentPostgresDriver
import JWTKit
import Vapor

public func configure(_ app: Application) async throws {
    if app.environment == .development {
        _ = DotEnv(withFile: ".env")
    }

    app.http.server.configuration.hostname = Environment.get("HOST") ?? "0.0.0.0"
    app.http.server.configuration.port = Environment.get("PORT").flatMap(Int.init) ?? 8080

    try DatabaseConfig.configure(app)
    try RedisConfig.configure(app)
    app.migrations.add(CreateRefreshTokens())

    await configureJWT(app)

    if let smtpHost = Environment.get("SMTP_HOSTNAME"),
        let smtpUser = Environment.get("SMTP_USERNAME"),
        let smtpPass = Environment.get("SMTP_PASSWORD"),
        let fromName = Environment.get("SMTP_FROM_NAME")
    {

        // ✅ Use new struct initializer
        let emailService = SMTPEmailService(
            hostname: smtpHost,
            email: smtpUser,
            password: smtpPass,
            fromName: fromName
        )
        app.storage[SMTPEmailServiceKey.self] = emailService

    } else {
        app.logger.warning("SMTP not fully configured - email verification disabled")
    }

    configureMiddleware(app)

    try routes(app)
}

private func configureJWT(_ app: Application) async {
    guard let jwtSecret = Environment.get("JWT_SECRET") else {
        fatalError("JWT_SECRET not set in environment")
    }

    let keys = JWTKeyCollection()
    await keys.add(hmac: HMACKey(from: jwtSecret), digestAlgorithm: .sha256)

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
