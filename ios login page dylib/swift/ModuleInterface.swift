//
//  ModuleInterface.swift
//  DefineAura
//
//  Decoupled interface for the authorized native application module.
//

import Foundation

public protocol ModuleInterfaceDelegate: AnyObject {
    func moduleDidUpdateStatus(_ statusMessage: String)
    func moduleDidEncounterError(_ error: Error)
}

public class ModuleInterface {
    public static let shared = ModuleInterface()
    
    public weak var delegate: ModuleInterfaceDelegate?
    public private(set) var isAuthorized: Bool = false
    public private(set) var isRunning: Bool = false
    
    public private(set) var currentSessionToken: String?
    public private(set) var currentLicenseKey: String?
    public private(set) var currentExpiryDate: String?
    
    private init() {}
    
    public func startModule(sessionToken: String, licenseKey: String, expiryDate: String?) {
        guard !sessionToken.isEmpty || !licenseKey.isEmpty else {
            print("[DefineAura] Unauthorized startup blocked.")
            return
        }
        
        self.isAuthorized = true
        self.currentSessionToken = sessionToken
        self.currentLicenseKey = licenseKey
        self.currentExpiryDate = expiryDate
        self.isRunning = true
        
        print("[DefineAura] Module initialized. Expiry: \(expiryDate ?? "N/A")")
        delegate?.moduleDidUpdateStatus("Module Active & Synchronized")
    }
    
    public func stopModule() {
        self.isRunning = false
        self.isAuthorized = false
        self.currentSessionToken = nil
        self.currentLicenseKey = nil
        self.currentExpiryDate = nil
        
        print("[DefineAura] Module stopped.")
        delegate?.moduleDidUpdateStatus("Module Deactivated")
    }
    
    public func executeFeatureAction(named name: String, parameters: [String: Any]? = nil) {
        guard isAuthorized && isRunning else {
            print("[DefineAura] Action '\(name)' blocked: unauthorized.")
            return
        }
        print("[DefineAura] Executing action '\(name)' with params: \(String(describing: parameters))")
    }
}
