import Fluent
import FluentPostgresDriver
import JWTKit
import Vapor
import DotEnv

public func configure(_ app: Application) async throws {
    if app.environment == .development {
        _ = DotEnv(withFile: ".env")
        app.logger.info("✅ .env file loaded successfully")
    }
    if let dbURL = Environment.get("DATABASE_URL") {
        let preview = String(dbURL.prefix(50))
        app.logger.info("📊 DATABASE_URL loaded: \(preview)...")
    } else {
        app.logger.error("❌ DATABASE_URL not found in environment!")
    }

    app.http.server.configuration.hostname = Environment.get("HOST") ?? "0.0.0.0"
    app.http.server.configuration.port = Environment.get("PORT").flatMap(Int.init) ?? 8080

    try DatabaseConfig.configure(app)
    app.migrations.add(CreateRefreshTokens())

    await configureJWT(app)

    // ✅ Configure Resend Email Service
    if let resendKey = Environment.get("RESEND_API_KEY"),
       let fromEmail = Environment.get("SMTP_FROM_EMAIL"),
       let fromName = Environment.get("SMTP_FROM_NAME")
    {
        let emailService = ResendEmailService(
            apiKey: resendKey,
            fromEmail: fromEmail,
            fromName: fromName
        )

        app.storage[ResendEmailServiceKey.self] = emailService
        app.logger.info("✅ Resend EmailService configured successfully")
    } else {
        app.logger.warning("⚠️ Resend not configured - email verification disabled")
    }

    configureMiddleware(app)

    try routes(app)

    app.logger.info("Using Supabase-managed database schema")
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
