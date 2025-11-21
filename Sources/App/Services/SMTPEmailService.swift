import Vapor
import SMTPKitten
import NIOSSL

struct SMTPEmailService: Sendable {
    private let hostname: String
    private let email: String
    private let password: String
    private let fromName: String

    init(hostname: String, email: String, password: String, fromName: String) {
        self.hostname = hostname
        self.email = email
        self.password = password
        self.fromName = fromName
    }

    func sendOTPEmail(to toEmail: String, otp: String, on eventLoop: any EventLoop) async throws {
        let subject = "Verify Your Email - AniVault"

        let htmlBody = """
        <div style="font-family: Arial, sans-serif; padding: 20px; max-width: 600px; margin: 0 auto;">
            <h2 style="color: #333;">Welcome to AniVault!</h2>
            <p>Your verification code is:</p>
            <div style="background-color: #f4f4f4; padding: 15px; font-size: 24px; font-weight: bold; text-align: center; letter-spacing: 5px; border-radius: 5px; margin: 20px 0;">
                \(otp)
            </div>
            <p>This code will expire in 10 minutes.</p>
            <p style="color: #666; font-size: 12px; margin-top: 30px;">If you didn't create an account, please ignore this email.</p>
        </div>
        """

        let textBody = "Your AniVault verification code is: \(otp)"

        let mail = Mail(
            from: .init(name: fromName, email: email),
            to: [.init(name: nil, email: toEmail)],
            subject: subject,
            content: .alternative(textBody, html: htmlBody)
        )

        let client = try await SMTPClient.connect(
            hostname: hostname,
            port: 587,
            ssl: .startTLS(configuration: .default),
            on: eventLoop
        )

        do {
            try await client.login(user: email, password: password)
            try await client.sendMail(mail)
            _ = try await client.sendWithoutResponse(.quit).get()
        } catch {
            _ = try? await client.sendWithoutResponse(.quit).get()
            throw error
        }
    }
}

struct SMTPEmailServiceKey: StorageKey {
    typealias Value = SMTPEmailService
}
