//
//  MostUsedPasswordChecker.swift
//  Amethyst Browser
//
//  Created by Mia Koring on 10.03.25.
//

import Foundation
import OSLog

@MainActor
class PasswordChecker {
    private static let logger = Logger(subsystem: AmethystApp.subSystem, category: "PasswordChecker")
    private var commonPasswords: Set<String> = []
    
    init() {
        loadCommonPasswords()
    }
    
    private func loadCommonPasswords() {
        if let fileURL = Bundle.main.url(forResource: "mostCommonPasswords", withExtension: "txt") {
            do {
                let passwordsContent = try String(contentsOf: fileURL, encoding: .utf8)
                let passwords = passwordsContent.components(separatedBy: .newlines)
                
                //convert to set for faster lookup
                commonPasswords = Set(passwords.filter { !$0.isEmpty })
                Self.logger.debug("Erfolgreich \(self.commonPasswords.count) Passwörter geladen")
            } catch {
                Self.logger.debug("Fehler beim Laden der Passwortdatei: \(error)")
            }
        } else {
            Self.logger.debug("Passwortdatei nicht gefunden")
        }
    }
    
    /// Checks if password list contains password
    /// - Parameter password
    func isCommonPassword(_ password: String) -> Bool {
        return commonPasswords.contains(password) || commonPasswords.contains(password.lowercased())
    }
    
    /// extended check with strength eval
    /// - Parameter password
    /// - Returns: Double (strength value)
    func checkPassword(_ password: String) -> Double {
        let isCommon = isCommonPassword(password)
        let strength = calculateStrength(password)
        
        Self.logger.debug("isPasswordCommon: \(isCommon)")
        
        return isCommon ? -1.0: strength
    }
    
    private func calculateStrength(_ password: String) -> Double {
        var score = 0.0
        
        if password.count >= 8 {
            score += 1
        }
        if password.count >= 12 {
            score += 1
        }
        if password.count >= 16 {
            score += 0.5
        }
        
        let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
        let hasDigit = password.range(of: "[0-9]", options: .regularExpression) != nil
        let hasSpecialChar = password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil
        
        if hasUppercase { score += 1 }
        if hasLowercase { score += 1 }
        if hasDigit { score += 1 }
        if hasSpecialChar { score += 1.5 }
        
        let hasThreeConsecutiveChars = password.range(of: "(.)\\1{2,}", options: .regularExpression) != nil
        if hasThreeConsecutiveChars { score -= 1 }
        
        return min(max(score / 7.0, 0.0), 1.0)
    }
}

