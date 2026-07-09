//
//  AuthenticatorHelper.swift
//  Amethyst Project
//
//  Created by Mia Koring on 03.06.25.
//

import Foundation

@MainActor
public struct AuthenticatorHelper {
    static func evaluatePasswordStrength(password: String) -> Double {
        let checker = PasswordChecker()
        return checker.checkPassword(password)
    }
    
    static func getRemainingTOTPTime() -> Int {
        let timeStep: TimeInterval = 30
        let currentTime = Date.now.timeIntervalSince1970
        let elapsedTime = currentTime.truncatingRemainder(dividingBy: timeStep)
        return Int((timeStep - elapsedTime).rounded(.toNearestOrEven))
    }
}
