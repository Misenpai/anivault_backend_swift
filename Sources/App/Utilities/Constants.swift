import Vapor

struct Constants {

    struct App {
        static let name = "AniVault API"
        static let version = "1.0.0"
        static let environment = Environment.get("ENVIRONMENT") ?? "development"
        static let isDevelopment = environment == "development"
        static let isProduction = environment == "production"
    }

    struct API {
        static let baseURL = Environment.get("API_BASE_URL") ?? "http://localhost:8080"
        static let version = "v1"
        static let prefix = "/api/\(version)"

        struct RateLimit {
            static let maxRequests = 100
            static let timeWindow: TimeInterval = 60
            static let maxLoginAttempts = 5
            static let loginAttemptWindow: TimeInterval = 900
        }
    }

    struct Database {
        static let maxConnections = Environment.get("DB_MAX_CONNECTIONS").flatMap(Int.init) ?? 10
        static let connectionTimeout: TimeInterval = 30
        static let queryTimeout: TimeInterval = 60
    }

    struct JWT {
        static let secret = Environment.get("JWT_SECRET") ?? "change-this-secret-in-production"
        static let expiration: TimeInterval = TimeInterval(
            Environment.get("JWT_EXPIRATION").flatMap(Int.init) ?? 604800)
        static let refreshExpiration: TimeInterval = TimeInterval(
            Environment.get("JWT_REFRESH_EXPIRATION").flatMap(Int.init) ?? 2_592_000)
        static let algorithm = "HS256"
        static let issuer = "anivault.api"
    }

    struct Email {
        static let fromEmail = Environment.get("SMTP_FROM_EMAIL") ?? "noreply@anivault.com"
        static let fromName = Environment.get("SMTP_FROM_NAME") ?? "AniVault"

        struct Verification {
            static let codeLength = 6
            static let codeExpiration: TimeInterval = 600
            static let maxResendAttempts = 3
            static let resendCooldown: TimeInterval = 60
        }

        struct Templates {
            static let verificationSubject = "Verify Your Email - AniVault"
            static let welcomeSubject = "Welcome to AniVault! 🎉"
            static let passwordResetSubject = "Reset Your Password - AniVault"
            static let friendInviteSubject = "You've Been Invited to Connect on AniVault"
        }
    }

    struct User {
        struct Username {
            static let minLength = 3
            static let maxLength = 20
            static let pattern = "^[a-zA-Z0-9_]{3,20}$"
            static let reservedNames = [
                "admin", "root", "system", "api", "www", "mail", "support", "help", "info",
            ]
        }

        struct Password {
            static let minLength = 8
            static let maxLength = 128
            static let requireUppercase = false
            static let requireLowercase = false
            static let requireNumber = false
            static let requireSpecialChar = false
        }

        struct Email {
            static let pattern = "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$"
            static let maxLength = 255
        }
    }

    struct Anime {
        static let maxTitleLength = 255
        static let minEpisodes = 1
        static let maxEpisodes = 9999

        struct Score {
            static let minScore: Double = 0
            static let maxScore: Double = 10
        }

        struct Status {
            static let watching = "Watching"
            static let completed = "Completed"
            static let planToWatch = "PlanToWatch"
            static let dropped = "Dropped"
            static let onHold = "OnHold"

            static let allStatuses = [watching, completed, planToWatch, dropped, onHold]
        }
    }

    struct Friends {
        static let maxFriends = 1000

        struct Invites {
            static let codeLength = 12
            static let defaultMaxUses = 1
            static let defaultExpiration: TimeInterval = 604800
            static let maxActiveInvitesPerUser = 10
        }
    }

    struct Pagination {
        static let defaultPage = 1
        static let defaultLimit = 25
        static let maxLimit = 100
        static let minLimit = 1
    }

    struct Upload {
        static let maxFileSize = Environment.get("MAX_FILE_SIZE").flatMap(Int.init) ?? 10_485_760
        static let uploadPath = Environment.get("UPLOAD_PATH") ?? "/var/uploads"

        struct Avatar {
            static let allowedExtensions = ["jpg", "jpeg", "png", "gif", "webp"]
            static let maxSize = 5_242_880
            static let defaultPath = "/avatars"
        }
    }

    struct JikanAPI {
        static let baseURL = "https://api.jikan.moe/v4"
        static let timeout: TimeInterval = 30
        static let cacheExpiration: TimeInterval = TimeInterval(
            Environment.get("JIKAN_CACHE_TTL").flatMap(Int.init) ?? 3600)
        static let maxRetries = 3
        static let retryDelay: TimeInterval = 1

        struct RateLimit {
            static let maxRequestsPerMinute = 60
            static let maxRequestsPerSecond = 3
        }

        struct Endpoints {
            static let anime = "/anime"
            static let search = "/anime"
            static let seasonNow = "/seasons/now"
            static let seasonUpcoming = "/seasons/upcoming"
            static let topAnime = "/top/anime"
        }
    }

    struct Cache {
        static let enabled = Environment.get("CACHE_ENABLED") == "true"
        static let defaultTTL: TimeInterval = 3600

        struct Keys {
            static let userPrefix = "user:"
            static let animePrefix = "anime:"
            static let jikanPrefix = "jikan:"
            static let statsPrefix = "stats:"
        }
    }

    enum Role: Int, CaseIterable {
        case admin = 1
        case user = 2
        case moderator = 3
        case guest = 4

        var title: String {
            switch self {
            case .admin: return "Admin"
            case .user: return "User"
            case .moderator: return "Moderator"
            case .guest: return "Guest"
            }
        }

        var permissions: [String] {
            switch self {
            case .admin:
                return ["all"]
            case .user:
                return ["read:own", "write:own", "delete:own"]
            case .moderator:
                return ["read:all", "write:own", "moderate"]
            case .guest:
                return ["read:public"]
            }
        }
    }

    struct Messages {
        struct Success {
            static let created = "Resource created successfully"
            static let updated = "Resource updated successfully"
            static let deleted = "Resource deleted successfully"
            static let retrieved = "Resource retrieved successfully"
        }

        struct Error {
            static let notFound = "Resource not found"
            static let unauthorized = "Unauthorized access"
            static let forbidden = "Access forbidden"
            static let badRequest = "Invalid request"
            static let internalError = "Internal server error"
            static let conflict = "Resource already exists"
        }

        struct Auth {
            static let loginSuccess = "Login successful"
            static let signupSuccess = "Account created successfully"
            static let logoutSuccess = "Logout successful"
            static let invalidCredentials = "Invalid email or password"
            static let emailExists = "Email already registered"
            static let usernameExists = "Username already taken"
            static let tokenExpired = "Token has expired"
            static let emailNotVerified = "Please verify your email address"
            static let verificationSent = "Verification code sent to your email"
            static let verificationSuccess = "Email verified successfully"
        }

        struct Anime {
            static let addedToList = "Anime added to your list"
            static let updatedInList = "Anime status updated"
            static let removedFromList = "Anime removed from your list"
            static let alreadyInList = "Anime already in your list"
            static let notInList = "Anime not found in your list"
        }

        struct Friends {
            static let inviteCreated = "Friend invite created"
            static let inviteAccepted = "Friend request accepted"
            static let friendRemoved = "Friend removed successfully"
            static let alreadyFriends = "Already friends"
            static let inviteExpired = "Invite code expired"
            static let inviteInvalid = "Invalid invite code"
        }
    }

    struct Validation {
        static let emailRegex = "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$"
        static let usernameRegex = "^[a-zA-Z0-9_]{3,20}$"
        static let urlRegex = "^https?://"
        static let phoneRegex = "^\\+?[1-9]\\d{1,14}$"
    }

    struct DateFormats {
        static let iso8601 = "yyyy-MM-dd'T'HH:mm:ssZ"
        static let date = "yyyy-MM-dd"
        static let time = "HH:mm:ss"
        static let display = "MMM dd, yyyy"
        static let displayWithTime = "MMM dd, yyyy HH:mm"
    }

    struct Logging {
        static let logLevel = Environment.get("LOG_LEVEL") ?? "info"
        static let logFormat = Environment.get("LOG_FORMAT") ?? "json"

        enum Level: String {
            case trace, debug, info, warning, error, critical
        }
    }

    struct Security {
        static let bcryptCost = 12
        static let maxRequestBodySize = "10mb"

        struct CORS {
            static let allowedOrigins =
                Environment.get("ALLOWED_ORIGINS")?.split(separator: ",").map(String.init) ?? ["*"]
            static let allowedMethods = ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"]
            static let allowedHeaders = [
                "Accept", "Authorization", "Content-Type", "Origin", "X-Requested-With",
            ]
        }
    }

    struct Features {
        static let emailVerificationRequired =
            Environment.get("EMAIL_VERIFICATION_REQUIRED") == "true"
        static let friendSystemEnabled = Environment.get("FRIEND_SYSTEM_ENABLED") != "false"
        static let publicProfilesEnabled = Environment.get("PUBLIC_PROFILES_ENABLED") != "false"
        static let animeRecommendationsEnabled =
            Environment.get("ANIME_RECOMMENDATIONS_ENABLED") == "true"
        static let socialFeedEnabled = Environment.get("SOCIAL_FEED_ENABLED") == "true"
    }

    struct ExternalServices {
        struct MAL {
            static let baseURL = "https://myanimelist.net"
            static let apiURL = "https://api.myanimelist.net/v2"
        }

        struct AniList {
            static let baseURL = "https://anilist.co"
            static let apiURL = "https://graphql.anilist.co"
        }
    }

    struct Time {
        static let minute: TimeInterval = 60
        static let hour: TimeInterval = 3600
        static let day: TimeInterval = 86400
        static let week: TimeInterval = 604800
        static let month: TimeInterval = 2_592_000
        static let year: TimeInterval = 31_536_000
    }
}

extension Constants {

    static func getEnvironmentValue(_ key: String, default defaultValue: String) -> String {
        return Environment.get(key) ?? defaultValue
    }

    static var isDevelopment: Bool {
        return App.isDevelopment
    }

    static var isProduction: Bool {
        return App.isProduction
    }
}

extension Environment {

    static func get<T>(_ key: String, as type: T.Type) -> T? where T: LosslessStringConvertible {
        guard let value = Environment.get(key) else { return nil }
        return T(value)
    }

    static func get(_ key: String, default defaultValue: String) -> String {
        return Environment.get(key) ?? defaultValue
    }
}
