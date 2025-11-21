import Vapor

final class ResendEmailService: @unchecked Sendable {
    private let apiKey: String
    private let fromEmail: String
    private let fromName: String
    
    init(apiKey: String, fromEmail: String, fromName: String) {
        self.apiKey = apiKey
        self.fromEmail = fromEmail
        self.fromName = fromName
    }
    
    func sendOTPEmail(to email: String, otp: String, client: Client) async throws {
        let emailContent = """
        Your AniVault verification code is: \(otp)
        
        This code will expire in 10 minutes.
        
        If you didn't create an account, please ignore this email.
        """
        
        struct ResendRequest: Content {
            let from: String
            let to: [String]
            let subject: String
            let text: String
        }
        
        let request = ResendRequest(
            from: "\(fromName) <\(fromEmail)>",
            to: [email],
            subject: "Verify Your Email - AniVault",
            text: emailContent
        )
        
        let response = try await client.post("https://api.resend.com/emails") { req in
            req.headers.add(name: "Authorization", value: "Bearer \(apiKey)")
            req.headers.add(name: "Content-Type", value: "application/json")
            try req.content.encode(request)
        }
        
        guard response.status == .ok else {
            throw Abort(.internalServerError, reason: "Failed to send email via Resend")
        }
    }
}