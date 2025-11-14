import Fluent
import Vapor

public func boot(_ app: Application) async throws {

    app.logger.info("Starting application boot sequence...")

    try await verifyDatabaseConnection(app)

    try await cleanupExpiredData(app)

    scheduleCleanupTasks(app)

    if Constants.App.isDevelopment {
        try await seedDevelopmentData(app)
    }

    try await logStartupStats(app)

    registerShutdownHandler(app)

    app.logger.info("Application boot completed successfully")
}

private func verifyDatabaseConnection(_ app: Application) async throws {
    app.logger.info("🔌 Verifying database connection...")

    do {

        _ = try await User.query(on: app.db).count()
        app.logger.info("Database connection verified")
    } catch {
        app.logger.error("Database connection failed: \(error)")
        throw error
    }
}

private func cleanupExpiredData(_ app: Application) async throws {
    app.logger.info("🧹 Cleaning up expired data...")

    let db = app.db
    let now = Date()

    let expiredTokens = try await RefreshToken.query(on: db)
        .group(.or) { group in
            group
                .filter(\.$expiresAt < now)
                .filter(\.$isRevoked == true)
        }
        .all()

    let expiredTokensCount = expiredTokens.count
    if expiredTokensCount > 0 {
        try await RefreshToken.query(on: db)
            .group(.or) { group in
                group
                    .filter(\.$expiresAt < now)
                    .filter(\.$isRevoked == true)
            }
            .delete()
        app.logger.info("🗑️  Deleted \(expiredTokensCount) expired/revoked refresh tokens")
    }

    let expiredVerifications = try await EmailVerification.query(on: db)
        .filter(\.$expiresAt < now)
        .all()

    let expiredVerificationsCount = expiredVerifications.count
    if expiredVerificationsCount > 0 {
        try await EmailVerification.query(on: db)
            .filter(\.$expiresAt < now)
            .delete()
        app.logger.info("🗑️  Deleted \(expiredVerificationsCount) expired email verifications")
    }

    let oldVerifications = try await EmailVerification.query(on: db)
        .filter(\.$createdAt < now.addingTimeInterval(-86400))
        .all()

    let oldVerificationsCount = oldVerifications.count
    if oldVerificationsCount > 0 {
        try await EmailVerification.query(on: db)
            .filter(\.$createdAt < now.addingTimeInterval(-86400))
            .delete()
        app.logger.info("🗑️  Deleted \(oldVerificationsCount) old email verifications")
    }

    app.logger.info("Data cleanup completed")
}

private func scheduleCleanupTasks(_ app: Application) {
    app.logger.info("⏰ Scheduling periodic cleanup tasks...")

    app.eventLoopGroup.next().scheduleRepeatedTask(
        initialDelay: .hours(1),
        delay: .hours(1)
    ) { task in
        app.logger.info("⏰ Running scheduled cleanup...")

        Task {
            do {
                try await cleanupExpiredData(app)
            } catch {
                app.logger.error("Scheduled cleanup failed: \(error)")
            }
        }
    }

    app.eventLoopGroup.next().scheduleRepeatedTask(
        initialDelay: .hours(6),
        delay: .hours(6)
    ) { task in
        Task {
            do {
                try await checkTokenHealth(app)
            } catch {
                app.logger.error("Token health check failed: \(error)")
            }
        }
    }

    app.logger.info("Cleanup tasks scheduled")
}

private func checkTokenHealth(_ app: Application) async throws {
    let db = app.db

    let soonToExpire = try await RefreshToken.query(on: db)
        .filter(\.$isRevoked == false)
        .filter(\.$expiresAt < Date().addingTimeInterval(7 * 86400))
        .filter(\.$expiresAt > Date())
        .count()

    if soonToExpire > 0 {
        app.logger.info("⚠️  \(soonToExpire) refresh tokens expiring in next 7 days")
    }
}

private func seedDevelopmentData(_ app: Application) async throws {
    app.logger.info("Seeding development data...")

    let db = app.db

    // ✅ Fixed: Use \.$role.$id instead of \.$roleId
    let adminExists =
        try await User.query(on: db)
        .filter(\.$role.$id == 1)
        .count() > 0

    if !adminExists {
        let adminPassword = try Bcrypt.hash("admin123")
        let admin = User(
            email: "admin@anivault.com",
            username: "admin",
            passwordHash: adminPassword,
            roleId: 1
        )
        admin.emailVerified = true
        try await admin.save(on: db)
        app.logger.info("👤 Created admin user: admin@anivault.com / admin123")
    }

    let testUserExists =
        try await User.query(on: db)
        .filter(\.$id == "test@anivault.com")
        .count() > 0

    if !testUserExists {
        let testPassword = try Bcrypt.hash("test123")
        let testUser = User(
            email: "test@anivault.com",
            username: "testuser",
            passwordHash: testPassword,
            roleId: 2
        )
        testUser.emailVerified = true
        try await testUser.save(on: db)
        app.logger.info("👤 Created test user: test@anivault.com / test123")
    }

    app.logger.info("✅ Development data seeded")
}

private func logStartupStats(_ app: Application) async throws {
    app.logger.info("📊 Gathering startup statistics...")

    let db = app.db

    let totalUsers = try await User.query(on: db).count()
    let verifiedUsers = try await User.query(on: db)
        .filter(\.$emailVerified == true)
        .count()
    let adminUsers = try await User.query(on: db)
        .filter(\.$role.$id == 1)
        .count()

    app.logger.info("👥 Total users: \(totalUsers)")
    app.logger.info("✉️  Verified users: \(verifiedUsers)")
    app.logger.info("👑 Admin users: \(adminUsers)")

    let activeTokens = try await RefreshToken.query(on: db)
        .filter(\.$isRevoked == false)
        .filter(\.$expiresAt > Date())
        .count()
    let totalTokens = try await RefreshToken.query(on: db).count()

    app.logger.info("🔑 Active refresh tokens: \(activeTokens) / \(totalTokens)")

    let pendingVerifications = try await EmailVerification.query(on: db)
        .filter(\.$expiresAt > Date())
        .count()

    app.logger.info("📧 Pending email verifications: \(pendingVerifications)")

    let totalAnime = try await UserAnimeStatus.query(on: db).count()
    let watchingCount = try await UserAnimeStatus.query(on: db)
        .filter(\.$status == .watching)
        .count()
    let completedCount = try await UserAnimeStatus.query(on: db)
        .filter(\.$status == .completed)
        .count()

    app.logger.info("🎬 Total anime entries: \(totalAnime)")
    app.logger.info("▶️  Currently watching: \(watchingCount)")
    app.logger.info("✅ Completed: \(completedCount)")

    app.logger.info("✅ Statistics gathered")
}

private func registerShutdownHandler(_ app: Application) {
    app.logger.info("🔧 Registering shutdown handler...")

    let signalQueue = DispatchQueue(label: "shutdown-handler")

    func handleShutdown(signal: Int32) {
        signalQueue.async {
            app.logger.info("🛑 Received shutdown signal (\(signal))")

            Task {
                do {
                    try await app.performGracefulShutdown()
                } catch {
                    app.logger.error("❌ Graceful shutdown failed: \(error)")
                }
            }
        }
    }

    signal(SIGTERM, SIG_IGN)
    signal(SIGINT, SIG_IGN)

    app.logger.info("✅ Shutdown handler registered")
}

extension Application {
    func performGracefulShutdown() async throws {
        logger.info("🛑 Performing graceful shutdown...")

        try await cleanupExpiredData(self)

        try await logShutdownStats(self)

        logger.info("✅ Graceful shutdown completed")
    }
}

private func logShutdownStats(_ app: Application) async throws {
    app.logger.info("📊 Final statistics:")

    let db = app.db

    let totalUsers = try await User.query(on: db).count()
    let activeTokens = try await RefreshToken.query(on: db)
        .filter(\.$isRevoked == false)
        .filter(\.$expiresAt > Date())
        .count()
    let totalAnime = try await UserAnimeStatus.query(on: db).count()

    app.logger.info("👥 Total users at shutdown: \(totalUsers)")
    app.logger.info("🔑 Active refresh tokens: \(activeTokens)")
    app.logger.info("🎬 Total anime entries: \(totalAnime)")
}
