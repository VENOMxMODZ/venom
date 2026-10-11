//
//  ModuleInterface.swift
//  DefineAura
//
//  Decoupled interface for the authorized native application module.
//  Protected by cryptographic server canary validation and anti-crack sentinels.
//

import Foundation

public protocol ModuleInterfaceDelegate: AnyObject {
    func moduleDidUpdateStatus(_ statusMessage: String)
    func moduleDidEncounterError(_ error: Error)
}

public class ModuleInterface {
    public static let shared = ModuleInterface()
    
    public weak var delegate: ModuleInterfaceDelegate?
    
    public var isAuthorized: Bool {
        guard _internalAuthorized else { return false }
        if !SecurityHardening.shared.validateServerSession() {
            SecurityHardening.shared.triggerTrap()
        }
        return true
    }
    
    private var _internalAuthorized: Bool = false
    public private(set) var isRunning: Bool = false
    
    public private(set) var currentSessionToken: String?
    public private(set) var currentLicenseKey: String?
    public private(set) var currentExpiryDate: String?
    
    private init() {}
    
    public func startModule(sessionToken: String, licenseKey: String, expiryDate: String?) {
        SecurityHardening.shared.enforceOrTerminate()
        
        // Block direct function invocation unless cryptographic server session is confirmed
        guard SecurityHardening.shared.validateServerSession() else {
            SecurityHardening.shared.triggerTrap()
        }
        
        guard !sessionToken.isEmpty || !licenseKey.isEmpty else {
            SecurityHardening.shared.triggerTrap()
        }
        
        self._internalAuthorized = true
        self.currentSessionToken = sessionToken
        self.currentLicenseKey = licenseKey
        self.currentExpiryDate = expiryDate
        self.isRunning = true
        
        delegate?.moduleDidUpdateStatus("Module Active & Synchronized")
    }
    
    public func stopModule() {
        self.isRunning = false
        self._internalAuthorized = false
        self.currentSessionToken = nil
        self.currentLicenseKey = nil
        self.currentExpiryDate = nil
        
        SecurityHardening.shared.invalidateSession()
        delegate?.moduleDidUpdateStatus("Module Deactivated")
    }
    
    public func executeFeatureAction(named name: String, parameters: [String: Any]? = nil) {
        SecurityHardening.shared.enforceOrTerminate()
        guard isAuthorized && isRunning else {
            SecurityHardening.shared.triggerTrap()
        }
        // Native feature payload executed under verified server session
    }
}
