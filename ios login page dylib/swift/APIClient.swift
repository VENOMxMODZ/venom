//
//  APIClient.swift
//  DefineAura
//
//  Secure HTTPS Client for VenomPanel Authentication API
//

import Foundation

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

public class APIClient {
    public static let shared = APIClient()
    
    public var endpointURL = "https://venompanel.shop/rootapi"
    public var gameName = "DefineAura"
    
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 15.0
        config.timeoutIntervalForResource = 30.0
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: config)
    }
    
    public func authenticate(licenseKey: String, deviceID: String, completion: @escaping (AuthResponse) -> Void) {
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
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("DefineAura/1.0 (iOS)", forHTTPHeaderField: "User-Agent")
        
        let payload: [String: Any] = [
            "game": gameName,
            "key": trimmedKey,
            "device_id": deviceID,
            "platform": "iOS"
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            DispatchQueue.main.async {
                completion(AuthResponse(status: .serverError, message: "Failed to serialize authentication payload."))
            }
            return
        }
        
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(AuthResponse(status: .networkError, message: "Network connection error: \(error.localizedDescription)"))
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
            
            guard let json = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any] else {
                let rawText = String(data: data, encoding: .utf8)?.lowercased() ?? ""
                DispatchQueue.main.async {
                    if rawText.contains("invalid") {
                        completion(AuthResponse(status: .invalidKey, message: "Invalid license key."))
                    } else if rawText.contains("expired") {
                        completion(AuthResponse(status: .expiredKey, message: "License key has expired."))
                    } else {
                        completion(AuthResponse(status: .serverError, message: "Invalid server response format."))
                    }
                }
                return
            }
            
            let authResponse = self.parseResponse(dict: json, statusCode: httpResponse.statusCode)
            DispatchQueue.main.async {
                completion(authResponse)
            }
        }.resume()
    }
    
    private func parseResponse(dict: [String: Any], statusCode: Int) -> AuthResponse {
        let statusVal = dict["status"] ?? dict["result"] ?? dict["success"]
        let msgVal = dict["message"] as? String ?? dict["msg"] as? String ?? dict["error"] as? String ?? ""
        let expiryVal = dict["expiry"] as? String ?? dict["expiry_date"] as? String ?? dict["expire"] as? String
        let tokenVal = dict["token"] as? String ?? dict["session_token"] as? String
        
        var isSuccess = false
        if let s = statusVal as? String {
            let lower = s.lowercased()
            isSuccess = (lower == "success" || lower == "true" || lower == "ok" || lower == "1")
        } else if let b = statusVal as? Bool {
            isSuccess = b
        } else if let n = statusVal as? Int {
            isSuccess = (n == 200 || n == 1)
        }
        
        if isSuccess && statusCode == 200 {
            let successMsg = msgVal.isEmpty ? "Authentication successful!" : msgVal
            return AuthResponse(status: .success, message: successMsg, token: tokenVal, expiryDate: expiryVal, rawPayload: dict)
        }
        
        let combined = "\(String(describing: statusVal)) \(msgVal)".lowercased()
        if combined.contains("expired") || combined.contains("out of date") {
            let msg = msgVal.isEmpty ? "This license key has expired." : msgVal
            return AuthResponse(status: .expiredKey, message: msg, rawPayload: dict)
        } else if combined.contains("invalid") || combined.contains("not found") || combined.contains("wrong") {
            let msg = msgVal.isEmpty ? "Invalid license key. Please check and try again." : msgVal
            return AuthResponse(status: .invalidKey, message: msg, rawPayload: dict)
        } else if statusCode >= 400 && statusCode < 500 {
            return AuthResponse(status: .invalidKey, message: "Authentication failed (Unauthorized).", rawPayload: dict)
        } else {
            let msg = msgVal.isEmpty ? "Server error encountered. Please try again later." : msgVal
            return AuthResponse(status: .serverError, message: msg, rawPayload: dict)
        }
    }
}
