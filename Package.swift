// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "anivault_backend",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        // 💧 Vapor web framework
        .package(url: "https://github.com/vapor/vapor.git", from: "4.115.0"),
        // 🗄 ORM
        .package(url: "https://github.com/vapor/fluent.git", from: "4.9.0"),
        // 🐘 PostgreSQL driver
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.8.0"),
        // 🔵 Async networking
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
        // 🔐 JWT
        .package(url: "https://github.com/vapor/jwt-kit.git", from: "5.3.0"),
        // 🧵 Queues + Redis
        .package(url: "https://github.com/mattmassicotte/Queue.git", from: "0.2.2"),
        .package(url: "https://github.com/vapor/queues-redis-driver.git", from: "1.1.2"),
        // 📧 SMTP
        .package(url: "https://github.com/Joannis/SMTPKitten.git", from: "0.2.3"),
        // dotenv
        .package(url: "https://github.com/swiftontheserver/swiftdotenv.git", from: "2.0.1")
    ],
    targets: [
        .target(
            name: "App",
            dependencies: [
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "JWTKit", package: "jwt-kit"),
                .product(name: "Queue", package: "queue"),
                .product(name: "QueuesRedisDriver", package: "queues-redis-driver"),
                .product(name: "SMTPKitten", package: "smtpkitten"),
                .product(name: "SwiftDotEnv", package: "swiftdotenv"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny")
            ]
        ),

        // MARK: Run target (entry point)
        .executableTarget(
            name: "Run",
            dependencies: [
                .target(name: "App")
            ],
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny")
            ]
        ),

        // MARK: Tests
        .testTarget(
            name: "AppTests",
            dependencies: [
                .target(name: "App"),
                .product(name: "XCTVapor", package: "vapor")
            ],
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny")
            ]
        ),
    ]
)
