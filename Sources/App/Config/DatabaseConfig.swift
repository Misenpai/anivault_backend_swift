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

        guard let config = try? SQLPostgresConfiguration(url: url) else {
            throw Abort(.internalServerError, reason: "Invalid database URL")
        }

        app.databases.use(
            .postgres(configuration: config),
            as: .psql
        )
    }

    private static func configureComponents(app: Application) throws {
        let hostname = Environment.get("DB_HOST") ?? "localhost"
        let port = Environment.get("DB_PORT").flatMap(Int.init) ?? 5432
        let username = Environment.get("DB_USER") ?? "postgres"
        let password = Environment.get("DB_PASSWORD") ?? ""
        let database = Environment.get("DB_NAME") ?? "postgres"

        var tlsConfig: TLSConfiguration?
        if Environment.get("DB_SSL_MODE") == "require" {
            tlsConfig = .makeClientConfiguration()
            tlsConfig?.certificateVerification = .none
        }

        let config = SQLPostgresConfiguration(
            hostname: hostname,
            port: port,
            username: username,
            password: password,
            database: database,
            tls: tlsConfig.map { .prefer(try! NIOSSLContext(configuration: $0)) } ?? .disable
        )

        app.databases.use(
            .postgres(configuration: config),
            as: .psql
        )
    }

    private static func configurePool(app: Application) {

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
