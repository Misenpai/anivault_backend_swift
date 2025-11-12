import Fluent
import FluentPostgresDriver
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
        guard let config = try? PostgresConfiguration(url: url) else {
            throw Abort(.internalServerError, reason: "Invalid database URL")
        }

        app.databases.use(.postgres(configuration: config), as: .psql)
    }

    private static func configureComponents(app: Application) throws {
        let hostname = Environment.get("DB_HOST") ?? "localhost"
        let port = Environment.get("DB_PORT").flatMap(Int.init) ?? 5432
        let username = Environment.get("DB_USER") ?? "postgres"
        let password = Environment.get("DB_PASSWORD") ?? ""
        let database = Environment.get("DB_NAME") ?? "anivault"

        var tlsConfig: TLSConfiguration?
        if let sslMode = Environment.get("DB_SSL_MODE"), sslMode == "require" {
            tlsConfig = .makeClientConfiguration()
            tlsConfig?.certificateVerification = .none
        }

        let config = PostgresConfiguration(
            hostname: hostname,
            port: port,
            username: username,
            password: password,
            database: database,
            tls: tlsConfig != nil ? .require(tlsConfig!) : .disable
        )

        app.databases.use(.postgres(configuration: config), as: .psql)
    }

    private static func configurePool(app: Application) {

        app.databases.use(
            .postgres(
                maxConnectionsPerEventLoop: Constants.Database.maxConnections,
                connectionPoolTimeout: .seconds(Int64(Constants.Database.connectionTimeout))
            ), as: .psql)
    }
}

struct DatabaseQueryLoggingMiddleware: AnyModelMiddleware {
    func create(model: AnyModel, on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void>
    {
        db.logger.info("Creating: \(type(of: model))")
        return next.create(model, on: db)
    }

    func update(model: AnyModel, on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void>
    {
        db.logger.info("Updating: \(type(of: model))")
        return next.update(model, on: db)
    }

    func delete(model: AnyModel, force: Bool, on db: Database, next: AnyModelResponder)
        -> EventLoopFuture<Void>
    {
        db.logger.info("Deleting: \(type(of: model))")
        return next.delete(model, force: force, on: db)
    }
}
