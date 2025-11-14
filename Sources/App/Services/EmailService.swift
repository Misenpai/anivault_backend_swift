import NIOCore
import NIOPosix
import SMTPKitten
import Vapor

final class EmailService: @unchecked Sendable {
    private let hostname: String
    private let port: Int
    private let username: String
    private let password: String
    private let fromEmail: String
    private let fromName: String

    init(
        hostname: String,
        port: Int,
        username: String,
        password: String,
        fromEmail: String,
        fromName: String
    ) {
        self.hostname = hostname
        self.port = port
        self.username = username
        self.password = password
        self.fromEmail = fromEmail
        self.fromName = fromName
    }

    func sendOTPEmail(to email: String, otp: String, on eventLoop: any EventLoop) async throws {

        let client = try await SMTPClient.connect(
            hostname: hostname,
            port: port,
            ssl: .startTLS(configuration: .default),
            on: eventLoop
        )

        defer {
            _ = client.sendWithoutResponse(.quit)
        }

        try await client.login(
            user: username,
            password: password
        )

        let mailText = """
            Your AniVault verification code is: \(otp)

            This code will expire in 10 minutes.

            If you didn't create an account, please ignore this email.
            """

        let mail = Mail(
            from: MailUser(name: fromName, email: fromEmail),
            to: [MailUser(name: "", email: email)],
            subject: "Verify Your Email - AniVault",
            content: .plain(mailText)
        )

        try await client.sendMail(mail)
    }
}