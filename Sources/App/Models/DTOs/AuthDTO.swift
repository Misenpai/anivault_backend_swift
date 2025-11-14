import Vapor

struct SignupRequest: Content, Validatable {
    let email: String
    let password: String

    static func validations(_ validations: inout Validations) {
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: .count(8...))
    }
}

struct LoginRequest: Content, Validatable {
    let identifier: String
    let password: String

    static func validations(_ validations: inout Validations) {
        validations.add("identifier", as: String.self, is: .count(3...))
        validations.add("password", as: String.self, is: .count(6...))
    }
}

struct RefreshTokenRequest: Content {
    let refreshToken: String
}

struct LogoutRequest: Content {
    let refreshToken: String
}

struct VerifyEmailRequest: Content {
    let email: String
}

struct VerifyCodeRequest: Content {
    let email: String
    let code: String
}

struct UpdateUsernameRequest: Content {
    let username: String
}
