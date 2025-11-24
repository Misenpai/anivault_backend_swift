import Redis
import Vapor

struct RedisConfig {
    static func configure(_ app: Application) throws {
        guard let hostname = Environment.get("REDIS_HOST") else {
            app.logger.warning("REDIS_HOST not set, skipping Redis configuration")
            return
        }

        let port = Environment.get("REDIS_PORT").flatMap(Int.init) ?? 6379
        let password = Environment.get("REDIS_PASSWORD")

        let configuration = try RedisConfiguration(
            hostname: hostname,
            port: port,
            password: password
        )

        app.redis.configuration = configuration

        app.caches.use(.redis)

        app.logger.info("✅ Redis configured as cache driver")
    }
}
