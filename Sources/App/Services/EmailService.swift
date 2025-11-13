import Vapor
import SMTPKitten
import NIOCore

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
    
    func sendOTPEmail(to email: String, otp: String, on eventLoop: EventLoop) async throws {
        // ✅ FIX: Use correct SMTPClient.connect signature
        let client = try await SMTPClient.connect(
            to: try .init(hostname: hostname, port: port),
            hostname: hostname,
            on: eventLoop
        )
        
        defer {
            _ = client.close()
        }
        
        try await client.login(
            user: username,
            password: password
        )
        
        let mail = Mail(
            from: MailUser(name: fromName, email: fromEmail),
            to: [MailUser(email: email)],
            subject: "Verify Your Email - AniVault",
            contentType: .plain,
            text: """
            Your AniVault verification code is: \(otp)
            
            This code will expire in 10 minutes.
            
            If you didn't create an account, please ignore this email.
            """
        )
        
        try await client.sendMail(mail)
    }
}