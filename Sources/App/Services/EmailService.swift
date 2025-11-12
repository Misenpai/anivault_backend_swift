//
//  EmailService.swift
//  anivault_backend
//
//  Created by Sumit Sinha on 09/11/25.
//

import Vapor
import SMTPKitten
import NIOCore


final class EmailService{
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
    ){
        self.hostname = hostname
        self.port = port
        self.username = username
        self.password = password
        self.fromEmail = fromEmail
        self.fromName = fromName
    }
    
    func sendOTPEmail(to email: String, otp: String, on eventLoop: EventLoop) async throws {
        let client = try await SMTPClient.connect(
            hostname: hostname,
            port: port,
            eventLoop: eventLoop,
            connectTimeout: .seconds(10)
        )
        
        defer {
            try? client.close().wait()
        }
        
        try await client.login(
            user: username,
            password: password
        )
        
        let mail = Mail(
            from: MailUser(name: fromName, email: fromEmail),
            to: [MailUser(email: email)],
            subject: "Verify Your Email - AniVault",
            contentType: .html,
            text: """
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="UTF-8">
                <style>
                    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                    .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
                             color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
                    .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
                    .otp-box { background: white; border: 2px dashed #667eea; padding: 20px; 
                              margin: 20px 0; text-align: center; border-radius: 8px; }
                    .otp-code { font-size: 32px; font-weight: bold; color: #667eea; 
                               letter-spacing: 8px; font-family: monospace; }
                    .footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
                    .button { display: inline-block; padding: 12px 30px; background: #667eea; 
                             color: white; text-decoration: none; border-radius: 5px; margin: 20px 0; }
                </style>
            </head>
            <body>
                <div class="container">
                    <div class="header">
                        <h1>🎌 AniVault</h1>
                        <p>Email Verification</p>
                    </div>
                    <div class="content">
                        <h2>Welcome to AniVault!</h2>
                        <p>Thank you for signing up. To complete your registration, please verify your email address.</p>
                        
                        <div class="otp-box">
                            <p style="margin: 0; color: #666;">Your verification code is:</p>
                            <div class="otp-code">\(otp)</div>
                            <p style="margin: 10px 0 0 0; color: #999; font-size: 14px;">
                                This code will expire in 10 minutes
                            </p>
                        </div>
                        
                        <p>If you didn't create an account with AniVault, please ignore this email.</p>
                        
                        <div class="footer">
                            <p>© 2025 AniVault. All rights reserved.</p>
                            <p>This is an automated email. Please do not reply.</p>
                        </div>
                    </div>
                </div>
            </body>
            </html>
            """
        )
        
        try await client.sendMail(mail)
    }
    
    func sendWelcomeEmail(to email: String, username: String, on eventLoop: EventLoop) async throws {
        let client = try await SMTPClient.connect(
            hostname: hostname,
            port: port,
            eventLoop: eventLoop,
            connectTimeout: .seconds(10)
        )
        
        defer {
            try? client.close().wait()
        }
        
        try await client.login(
            user: username,
            password: password
        )
        
        let mail = Mail(
            from: MailUser(name: fromName, email: fromEmail),
            to: [MailUser(email: email)],
            subject: "Welcome to AniVault! 🎉",
            contentType: .html,
            text: """
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="UTF-8">
                <style>
                    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                    .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
                             color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
                    .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
                    .feature { background: white; padding: 15px; margin: 10px 0; border-radius: 5px; 
                              border-left: 4px solid #667eea; }
                </style>
            </head>
            <body>
                <div class="container">
                    <div class="header">
                        <h1>🎌 Welcome to AniVault!</h1>
                    </div>
                    <div class="content">
                        <h2>Hi @\(username)! 👋</h2>
                        <p>Your email has been verified successfully. You're all set to start your anime journey!</p>
                        
                        <h3>What you can do now:</h3>
                        <div class="feature">
                            ✨ Track your anime watching progress
                        </div>
                        <div class="feature">
                            👥 Connect with friends and share your anime lists
                        </div>
                        <div class="feature">
                            🔍 Discover new anime from current and upcoming seasons
                        </div>
                        <div class="feature">
                            📊 View your anime statistics
                        </div>
                        
                        <p style="margin-top: 30px;">Happy watching! 🍿</p>
                        <p><strong>The AniVault Team</strong></p>
                    </div>
                </div>
            </body>
            </html>
            """
        )
        
        try await client.sendMail(mail)
    }
}
