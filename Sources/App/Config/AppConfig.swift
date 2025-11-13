import Vapor

struct AppConfig {

    static func configure(_ app: Application) {

        configureServer(app)

        configureLogging(app)

        configureSecurity(app)

        displayStartupInfo(app)
    }

    private static func configureServer(_ app: Application) {

        app.http.server.configuration.hostname = Environment.get("HOST") ?? "0.0.0.0"
        app.http.server.configuration.port = Environment.get("PORT").flatMap(Int.init) ?? 8080

        app.routes.defaultMaxBodySize = "10mb"

        app.http.server.configuration.requestDecompression = .enabled(limit: .size(10_000_000))
    }

    private static func configureLogging(_ app: Application) {

        if let logLevel = Environment.get("LOG_LEVEL") {
            app.logger.logLevel = Logger.Level(rawValue: logLevel) ?? .info
        } else {
            app.logger.logLevel = Constants.App.isDevelopment ? .debug : .info
        }
    }

    private static func configureSecurity(_ app: Application) {

        app.middleware.use(SecurityHeadersMiddleware())

        app.http.server.configuration.serverName = nil
    }

    private static func displayStartupInfo(_ app: Application) {
        app.logger.info("🚀 \(Constants.App.name) v\(Constants.App.version)")
        app.logger.info("📍 Environment: \(Constants.App.environment)")
        app.logger.info(
            "🌐 Server: \(app.http.server.configuration.hostname):\(app.http.server.configuration.port)"
        )
        app.logger.info("💾 Database: PostgreSQL")
        app.logger.info("🔐 JWT: Enabled")

        if Constants.Features.emailVerificationRequired {
            app.logger.info("📧 Email Verification: Required")
        }

        if Constants.Features.friendSystemEnabled {
            app.logger.info("👥 Friend System: Enabled")
        }
    }
}

struct SecurityHeadersMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: any Responder) -> EventLoopFuture<Response> {
        return next.respond(to: request).map { response in

            response.headers.add(name: "X-Content-Type-Options", value: "nosniff")
            response.headers.add(name: "X-Frame-Options", value: "DENY")
            response.headers.add(name: "X-XSS-Protection", value: "1; mode=block")
            response.headers.add(name: "Referrer-Policy", value: "strict-origin-when-cross-origin")

            return response
        }
    }
}
