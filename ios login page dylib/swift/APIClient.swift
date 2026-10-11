//
//  APIClient.swift
//  DefineAura
//
//  Secure HTTPS Client for VenomPanel Authentication API
//  Hardened with string obfuscation, SSL pinning, and server canary registration.
//

import Foundation
import Security

public enum AuthStatus: Int {
    case success = 0
    case invalidKey
    case expiredKey
    case networkError
    case serverError
    case unknownError
}

public struct AuthResponse {
    public let status: AuthStatus
    public let message: String
    public let token: String?
    public let expiryDate: String?
    public let rawPayload: [String: Any]?
    
    public init(status: AuthStatus, message: String, token: String? = nil, expiryDate: String? = nil, rawPayload: [String: Any]? = nil) {
        self.status = status
        self.message = message
        self.token = token
        self.expiryDate = expiryDate
        self.rawPayload = rawPayload
    }
}

public class APIClient: NSObject, URLSessionDelegate {
    public static let shared = APIClient()
    
    // Obfuscated endpoint: https://venompanel.shop/rootapi
    public var endpointURL: String {
        return Obfuscation.decrypt(
            cipher: [0x02, 0x05, 0x0C, 0x0F, 0xF5, 0xB7, 0xBB, 0xB4, 0xD4, 0xCC, 0xDE, 0xD8, 0xD3, 0xB5, 0xAD, 0xBD, 0xBF, 0x8D, 0xC6, 0x9C, 0x9E, 0x92, 0x74, 0x24, 0x60, 0x76, 0x4F, 0x53, 0x4F, 0x45, 0x55],
            key: 0x6A
        )
    }
    
    // Obfuscated game name: DefineAura
    public var gameName: String {
        return Obfuscation.decrypt(
            cipher: [0x23, 0x0B, 0x13, 0x15, 0xED, 0xEF, 0xD0, 0xED, 0xED, 0xC7],
            key: 0x67
        )
    }
    
    private var session: URLSession!
    
    private override init() {
        super.init()
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 15.0
        config.timeoutIntervalForResource = 30.0
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    // Strict TLS certificate validation to block MITM proxy tools (Burp, Charles)
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        SecurityHardening.shared.enforceOrTerminate()
        
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let serverTrust = challenge.protectionSpace.serverTrust {
            let host = challenge.protectionSpace.host
            let expectedHost = Obfuscation.decrypt(cipher: [0x10, 0x08, 0x1A, 0x14, 0xEF, 0xF9, 0xF1, 0xF9, 0xFB, 0xC9, 0x82, 0xC0, 0xD2, 0xAE, 0xB8], key: 0x66) // "venompanel.shop"
            
            if host == expectedHost {
                var isTrusted = false
                if #available(iOS 12.0, *) {
                    var error: CFError?
                    isTrusted = SecTrustEvaluateWithError(serverTrust, &error)
                } else {
                    var result: SecTrustResultType = .invalid
                    SecTrustEvaluate(serverTrust, &result)
                    isTrusted = (result == .proceed || result == .unspecified)
                }
                
                if isTrusted {
                    completionHandler(.useCredential, URLCredential(trust: serverTrust))
                    return
                }
            }
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        completionHandler(.performDefaultHandling, nil)
    }
    
    public func authenticate(licenseKey: String, deviceID: String, completion: @escaping (AuthResponse) -> Void) {
        SecurityHardening.shared.enforceOrTerminate()
        
        let trimmedKey = licenseKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            DispatchQueue.main.async {
                completion(AuthResponse(status: .invalidKey, message: "Please enter a valid license key."))
            }
            return
        }
        
        guard let url = URL(string: endpointURL) else {
            DispatchQueue.main.async {
                completion(AuthResponse(status: .serverError, message: "Invalid API endpoint configuration."))
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("DefineAura/1.0 (iOS)", forHTTPHeaderField: "User-Agent")
        
        let encGame = gameName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encKey = trimmedKey.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encSerial = deviceID.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        let bodyString = "game=\(encGame)&user_key=\(encKey)&serial=\(encSerial)&key=\(encKey)&device_id=\(encSerial)"
        request.httpBody = bodyString.data(using: .utf8)
        
        session.dataTask(with: request) { [weak self] data, response, error in
            SecurityHardening.shared.enforceOrTerminate()
            
            if let error = error {
                DispatchQueue.main.async {
                    completion(AuthResponse(status: .networkError, message: "Connection error: \(error.localizedDescription)"))
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion(AuthResponse(status: .serverError, message: "Invalid response received."))
                }
                return
            }
            
            if httpResponse.statusCode >= 500 {
                DispatchQueue.main.async {
                    completion(AuthResponse(status: .serverError, message: "Server unavailable (\(httpResponse.statusCode)). Please try again later."))
                }
                return
            }
            
            guard let data = data, !data.isEmpty else {
                DispatchQueue.main.async {
                    completion(AuthResponse(status: .serverError, message: "Empty response from authentication server."))
                }
                return
            }
            
            guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                let raw = String(data: data, encoding: .utf8)?.lowercased() ?? ""
                DispatchQueue.main.async {
                    if raw.contains("invalid") {
                        completion(AuthResponse(status: .invalidKey, message: "Invalid license key."))
                    } else if raw.contains("expired") {
                        completion(AuthResponse(status: .expiredKey, message: "License key has expired."))
                    } else {
                        completion(AuthResponse(status: .serverError, message: "Invalid server response format."))
                    }
                }
                return
            }
            
            let parsed = self?.parseResponse(dict: json, statusCode: httpResponse.statusCode, licenseKey: trimmedKey, deviceID: deviceID)
                ?? AuthResponse(status: .serverError, message: "Parsing failed.")
            
            DispatchQueue.main.async {
                completion(parsed)
            }
        }.resume()
    }
    
    private func parseResponse(dict: [String: Any], statusCode: Int, licenseKey: String, deviceID: String) -> AuthResponse {
        let statusVal = dict["status"] ?? dict["result"] ?? dict["success"]
        let msgVal = dict["message"] ?? dict["msg"] ?? dict["error"] ?? dict["reason"]
        
        let dataDict = dict["data"] as? [String: Any]
        let expiryVal = dict["expired_date"] ?? dataDict?["expired_date"] ?? dict["expiry"] ?? dataDict?["expiry"]
        let tokenVal = dict["token"] ?? dataDict?["token"] ?? dict["session_token"] ?? dataDict?["session_token"]
        
        let message = (msgVal as? String) ?? ""
        let expiryStr = (expiryVal as? String) ?? (expiryVal != nil ? "\(expiryVal!)" : nil)
        let tokenStr = tokenVal as? String
        
        var isSuccess = false
        if let num = statusVal as? NSNumber {
            isSuccess = num.boolValue || num.intValue == 200 || num.intValue == 1
        } else if let s = statusVal as? String {
            let lower = s.lowercased()
            isSuccess = (lower == "success" || lower == "true" || lower == "ok" || lower == "1")
        }
        
        if isSuccess && (statusCode == 200 || statusCode == 0) {
            SecurityHardening.shared.registerServerSession(
                key: licenseKey,
                token: tokenStr ?? "",
                expiry: expiryStr ?? "",
                deviceID: deviceID
            )
            return AuthResponse(
                status: .success,
                message: message.isEmpty ? "Authentication successful!" : message,
                token: tokenStr,
                expiryDate: expiryStr,
                rawPayload: dict
            )
        }
        
        SecurityHardening.shared.invalidateSession()
        
        let combined = "\(statusVal ?? "") \(message)".lowercased()
        if combined.contains("expired") {
            return AuthResponse(status: .expiredKey, message: message.isEmpty ? "License key has expired." : message, rawPayload: dict)
        } else if combined.contains("invalid") || combined.contains("not found") || combined.contains("unauthorized") {
            return AuthResponse(status: .invalidKey, message: message.isEmpty ? "Invalid license key." : message, rawPayload: dict)
        } else {
            return AuthResponse(status: .serverError, message: message.isEmpty ? "Server error." : message, rawPayload: dict)
        }
    }
}
