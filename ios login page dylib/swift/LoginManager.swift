//
//  LoginManager.swift
//  DefineAura
//
//  Coordinates login authentication flow, session validation, and module startup.
//

import Foundation

public protocol LoginManagerDelegate: AnyObject {
    func loginDidBeginAuthenticating()
    func loginDidSucceed(response: AuthResponse)
    func loginDidFail(status: AuthStatus, message: String)
}

public class LoginManager {
    public static let shared = LoginManager()
    
    public weak var delegate: LoginManagerDelegate?
    public private(set) var isAuthenticated: Bool = false
    
    private init() {}
    
    public func login(key: String) {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            delegate?.loginDidFail(status: .invalidKey, message: "License key cannot be empty.")
            return
        }
        
        delegate?.loginDidBeginAuthenticating()
        let deviceID = SessionManager.shared.getOrCreateDeviceIdentifier()
        
        APIClient.shared.authenticate(licenseKey: trimmed, deviceID: deviceID) { [weak self] response in
            guard let self = self else { return }
            
            if response.status == .success {
                self.isAuthenticated = true
                SessionManager.shared.saveLicenseKey(trimmed)
                if let token = response.token {
                    SessionManager.shared.saveSessionToken(token)
                }
                if let expiry = response.expiryDate {
                    SessionManager.shared.saveExpiryDate(expiry)
                }
                
                ModuleInterface.shared.startModule(sessionToken: response.token ?? "",
                                                   licenseKey: trimmed,
                                                   expiryDate: response.expiryDate)
                
                self.delegate?.loginDidSucceed(response: response)
            } else {
                self.isAuthenticated = false
                self.delegate?.loginDidFail(status: response.status, message: response.message)
            }
        }
    }
    
    public func attemptCachedLogin() {
        if let key = SessionManager.shared.getStoredLicenseKey(), !key.isEmpty {
            login(key: key)
        }
    }
    
    public func logout() {
        isAuthenticated = false
        ModuleInterface.shared.stopModule()
        SessionManager.shared.clearAllSessionData()
    }
}
