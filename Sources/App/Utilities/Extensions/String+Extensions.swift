import Foundation
import Vapor

extension String {

    func isValidEmail() -> Bool {
        let emailPredicate = NSPredicate(
            format: "SELF MATCHES[c] %@", Constants.Validation.emailRegex)
        return emailPredicate.evaluate(with: self)
    }

    func isValidUsername() -> Bool {
        let usernamePredicate = NSPredicate(
            format: "SELF MATCHES %@", Constants.Validation.usernameRegex)
        return usernamePredicate.evaluate(with: self)
    }

    func isReservedUsername() -> Bool {
        return Constants.User.Username.reservedNames.contains(self.lowercased())
    }

    func isValidURL() -> Bool {
        let urlPredicate = NSPredicate(format: "SELF MATCHES %@", Constants.Validation.urlRegex)
        return urlPredicate.evaluate(with: self)
    }

    func isValidPhoneNumber() -> Bool {
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", Constants.Validation.phoneRegex)
        return phonePredicate.evaluate(with: self)
    }

    func trimmed() -> String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func removingWhitespace() -> String {
        return components(separatedBy: .whitespaces).joined()
    }

    func sanitized() -> String {
        return
            self
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#x27;")
            .replacingOccurrences(of: "/", with: "&#x2F;")
    }

    func truncated(to length: Int, trailing: String = "...") -> String {
        guard count > length else { return self }
        return prefix(length - trailing.count) + trailing
    }

    func toSnakeCase() -> String {
        let pattern = "([a-z0-9])([A-Z])"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: count)
        return regex?.stringByReplacingMatches(
            in: self,
            options: [],
            range: range,
            withTemplate: "$1_$2"
        ).lowercased() ?? lowercased()
    }

    func toCamelCase() -> String {
        let components = split(separator: "_")
        guard !components.isEmpty else { return self }

        let first = String(components[0]).lowercased()
        let rest = components.dropFirst().map { String($0).capitalized }

        return ([first] + rest).joined()
    }

    func base64Encoded() -> String? {
        return data(using: .utf8)?.base64EncodedString()
    }

    func base64Decoded() -> String? {
        guard let data = Data(base64Encoded: self) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func urlEncoded() -> String? {
        return addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    }

    func urlDecoded() -> String? {
        return removingPercentEncoding
    }

    func sha256() -> String {
        let data = Data(utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    static func random(
        length: Int,
        characters: String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    ) -> String {
        return String((0..<length).map { _ in characters.randomElement()! })
    }

    static func randomAlphanumeric(length: Int) -> String {
        return random(
            length: length,
            characters: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
    }

    static func randomNumeric(length: Int) -> String {
        return random(length: length, characters: "0123456789")
    }

    var emailUsername: String? {
        return components(separatedBy: "@").first
    }

    var emailDomain: String? {
        return components(separatedBy: "@").last
    }

    func pluralized(count: Int) -> String {
        return count == 1 ? self : self + "s"
    }

    func maskedEmail() -> String {
        let components = split(separator: "@")
        guard components.count == 2 else { return self }

        let username = String(components[0])
        let domain = String(components[1])

        if username.count <= 3 {
            return "\(username)***@\(domain)"
        }

        let visible = username.prefix(3)
        return "\(visible)***@\(domain)"
    }

    func maskedPhone() -> String {
        guard count >= 4 else { return self }
        let masked = String(repeating: "*", count: count - 4)
        let visible = suffix(4)
        return masked + visible
    }

    var isAlphanumeric: Bool {
        return !isEmpty && rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) == nil
    }

    var isNumeric: Bool {
        return !isEmpty && rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
    }

    var isAlphabetic: Bool {
        return !isEmpty && rangeOfCharacter(from: CharacterSet.letters.inverted) == nil
    }
}

extension Optional where Wrapped == String {

    var isNilOrEmpty: Bool {
        return self?.isEmpty ?? true
    }

    func orEmpty() -> String {
        return self ?? ""
    }
}
