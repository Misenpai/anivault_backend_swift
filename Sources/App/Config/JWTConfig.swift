import JWTKit
import Vapor

struct JWTConfig {

    static func configure(_ app: Application) throws {

        guard let jwtSecret = Environment.get("JWT_SECRET") else {
            app.logger.warning("JWT_SECRET not set, using default (INSECURE)")

            if Constants.App.isProduction {
                throw Abort(.internalServerError, reason: "JWT_SECRET must be set in production")
            }

            configureSigners(app: app, secret: "default-secret-change-in-production")
            return
        }

        guard jwtSecret.count >= 32 else {
            throw Abort(.internalServerError, reason: "JWT_SECRET must be at least 32 characters")
        }

        configureSigners(app: app, secret: jwtSecret)
    }

    private static func configureSigners(app: Application, secret: String) {

        app.jwt.signers.use(.hs256(key: secret))

        app.logger.info("JWT configured with HS256 algorithm")
        app.logger.info("JWT expiration: \(Constants.JWT.expiration) seconds")
    }
}
