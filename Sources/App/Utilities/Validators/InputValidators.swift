import Vapor

struct UsernameValidator: ValidatorType {
    func validate(_ value: String) -> ValidatorResult {

        guard value.count >= Constants.User.Username.minLength,
            value.count <= Constants.User.Username.maxLength
        else {
            return .failure(
                "Username must be \(Constants.User.Username.minLength)-\(Constants.User.Username.maxLength) characters"
            )
        }

        guard value.isValidUsername() else {
            return .failure("Username can only contain letters, numbers, and underscores")
        }

        guard !value.isReservedUsername() else {
            return .failure("Username is reserved")
        }

        return .success
    }
}

struct PasswordValidator: ValidatorType {
    func validate(_ value: String) -> ValidatorResult {

        guard value.count >= Constants.User.Password.minLength else {
            return .failure(
                "Password must be at least \(Constants.User.Password.minLength) characters")
        }

        guard value.count <= Constants.User.Password.maxLength else {
            return .failure("Password is too long")
        }

        if Constants.User.Password.requireUppercase {
            guard value.rangeOfCharacter(from: .uppercaseLetters) != nil else {
                return .failure("Password must contain at least one uppercase letter")
            }
        }

        if Constants.User.Password.requireLowercase {
            guard value.rangeOfCharacter(from: .lowercaseLetters) != nil else {
                return .failure("Password must contain at least one lowercase letter")
            }
        }

        if Constants.User.Password.requireNumber {
            guard value.rangeOfCharacter(from: .decimalDigits) != nil else {
                return .failure("Password must contain at least one number")
            }
        }

        if Constants.User.Password.requireSpecialChar {
            let specialCharacters = CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")
            guard value.rangeOfCharacter(from: specialCharacters) != nil else {
                return .failure("Password must contain at least one special character")
            }
        }

        return .success
    }
}

struct URLValidator: ValidatorType {
    func validate(_ value: String) -> ValidatorResult {
        guard value.isValidURL() else {
            return .failure("Invalid URL format")
        }
        return .success
    }
}

extension ValidatorResults {

    public static var username: ValidatorResults<String> {
        .init {
            UsernameValidator().validate($0)
        }
    }

    public static var password: ValidatorResults<String> {
        .init {
            PasswordValidator().validate($0)
        }
    }

    public static var url: ValidatorResults<String> {
        .init {
            URLValidator().validate($0)
        }
    }
}
