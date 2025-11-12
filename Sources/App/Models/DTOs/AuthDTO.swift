//
//  AuthDTO.swift
//  anivault_backend
//
//  Created by Sumit Sinha on 08/11/25.
//

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
    let email: String
    let password: String
    
    static func validations(_ validations: inout Validations) {
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: .count(6...))
    }
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
