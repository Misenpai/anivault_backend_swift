import Vapor

struct EmailValidator: ValidatorType {
    func validate(_ value: String) -> ValidatorResult {
        guard value.isValidEmail() else {
            return .failure("Invalid email format")
        }

        guard value.count <= Constants.User.Email.maxLength else {
            return .failure("Email is too long")
        }

        return .success
    }
}

extension ValidatorResults {

    public static var email: ValidatorResults<String> {
        .init {
            EmailValidator().validate($0)
        }
    }
}
