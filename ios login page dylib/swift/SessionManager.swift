//
//  SessionManager.swift
//  DefineAura
//
//  Secure Keychain Storage and Session State Manager
//

import Foundation
import Security
import UIKit

public class SessionManager {
    public static let shared = SessionManager()
    
    private let serviceIdentifier = "com.defineaura.auth"
    private let keyDeviceUUID     = "deviceID"
    private let keyLicenseKey     = "licenseKey"
    private let keySessionToken   = "sessionToken"
    private let keyExpiryDate     = "expiryDate"
    
    private init() {}
    
    // MARK: - Keychain Core
    
    @discardableResult
    private func saveToKeychain(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            let updateQuery: [String: Any] = [
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            ]
            let updateStatus = SecItemUpdate(query as CFDictionary, updateQuery as CFDictionary)
            return updateStatus == errSecSuccess
        } else if status == errSecItemNotFound {
            var newQuery = query
            newQuery[kSecValueData as String] = data
            newQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            let addStatus = SecItemAdd(newQuery as CFDictionary, nil)
            return addStatus == errSecSuccess
        }
        return false
    }
    
    private func getFromKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess, let data = result as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    @discardableResult
    private func deleteFromKeychain(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    // MARK: - Public API
    
    public func getOrCreateDeviceIdentifier() -> String {
        if let existing = getFromKeychain(key: keyDeviceUUID), !existing.isEmpty {
            return existing
        }
        let newUUID = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        saveToKeychain(key: keyDeviceUUID, value: newUUID)
        return newUUID
    }
    
    public func saveLicenseKey(_ key: String) {
        saveToKeychain(key: keyLicenseKey, value: key)
    }
    
    public func getStoredLicenseKey() -> String? {
        return getFromKeychain(key: keyLicenseKey)
    }
    
    public func clearStoredLicenseKey() {
        deleteFromKeychain(key: keyLicenseKey)
    }
    
    public func saveSessionToken(_ token: String) {
        saveToKeychain(key: keySessionToken, value: token)
    }
    
    public func getStoredSessionToken() -> String? {
        return getFromKeychain(key: keySessionToken)
    }
    
    public func clearStoredSessionToken() {
        deleteFromKeychain(key: keySessionToken)
    }
    
    public func saveExpiryDate(_ date: String) {
        saveToKeychain(key: keyExpiryDate, value: date)
    }
    
    public func getStoredExpiryDate() -> String? {
        return getFromKeychain(key: keyExpiryDate)
    }
    
    public func clearAllSessionData() {
        clearStoredLicenseKey()
        clearStoredSessionToken()
        deleteFromKeychain(key: keyExpiryDate)
    }
}
