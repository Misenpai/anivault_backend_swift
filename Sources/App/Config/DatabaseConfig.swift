import Fluent
import FluentPostgresDriver
import NIOSSL
import Vapor

struct DatabaseConfig {

    static func configure(_ app: Application) throws {

        if let databaseURL = Environment.get("DATABASE_URL") {
            try configureDatabaseURL(databaseURL, app: app)
        } else {
            try configureComponents(app: app)
        }

        configurePool(app: app)

        if Constants.App.isDevelopment {
            app.databases.middleware.use(DatabaseQueryLoggingMiddleware())
        }
    }

    private static func configureDatabaseURL(_ url: String, app: Application) throws {

        guard var config = try? SQLPostgresConfiguration(url: url) else {
            throw Abort(.internalServerError, reason: "Invalid database URL")
        }

        // ✅ Configure TLS to work with Supabase
        var tlsConfig = TLSConfiguration.makeClientConfiguration()
        tlsConfig.certificateVerification = .none  // Disable certificate verification for Supabase
        
        do {
            let sslContext = try NIOSSLContext(configuration: tlsConfig)
            config.coreConfiguration.tls = .require(sslContext)
        } catch {
            app.logger.error("Failed to configure TLS: \(error)")
            throw Abort(.internalServerError, reason: "TLS configuration failed")
        }

        app.databases.use(
            .postgres(configuration: config),
            as: .psql
        )
        
        app.logger.info("✅ Database configured with TLS")
    }

    private static func configureComponents(app: Application) throws {
        let hostname = Environment.get("DB_HOST") ?? "localhost"
        let port = Environment.get("DB_PORT").flatMap(Int.init) ?? 5432
        let username = Environment.get("DB_USER") ?? "postgres"
        let password = Environment.get("DB_PASSWORD") ?? ""
        let database = Environment.get("DB_NAME") ?? "postgres"

        var tlsConfig = TLSConfiguration.makeClientConfiguration()
        tlsConfig.certificateVerification = .none

        let sslContext = try? NIOSSLContext(configuration: tlsConfig)

        let config = SQLPostgresConfiguration(
            hostname: hostname,
            port: port,
            username: username,
            password: password,
            database: database,
            tls: sslContext.map { .require($0) } ?? .disable
        )

        app.databases.use(
            .postgres(configuration: config),
            as: .psql
        )
    }

    private static func configurePool(app: Application) {
        // Connection pool settings can be configured here if needed
    }
}

struct DatabaseQueryLoggingMiddleware: AnyModelMiddleware {
    func handle(
        _ event: ModelEvent, _ model: any AnyModel, on db: any Database,
        chainingTo next: any AnyModelResponder
    ) -> EventLoopFuture<Void> {
        db.logger.info("Database operation: \(event) on \(type(of: model))")
        return next.handle(event, model, on: db)
    }
}