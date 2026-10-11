//
//  SecurityHardening.swift
//  DefineAura - Military-Grade Anti-Tamper & Anti-Crack Protection Suite
//

import Foundation
import Darwin

public final class SecurityHardening {
    public static let shared = SecurityHardening()
    
    private var sessionCanary: UInt64 = 0
    private var expectedCanary: UInt64 = 0
    private var watchdogTimer: DispatchSourceTimer?
    
    private init() {}
    
    public func startSentinel() {
        invokeAntiDebug()
        enforceOrTerminate()
        
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .background))
        timer.schedule(deadline: .now() + 3.0, repeating: 3.5)
        timer.setEventHandler { [weak self] in
            self?.invokeAntiDebug()
            self?.enforceOrTerminate()
            self?.verifyCanaryIntegrity()
        }
        timer.resume()
        self.watchdogTimer = timer
    }
    
    public func enforceOrTerminate() {
        if isDebuggerAttached() || detectInjectedLibraries() || detectJailbreak() {
            triggerTrap()
        }
    }
    
    public func triggerTrap() -> Never {
        #if arch(arm64)
        // Hard crash instruction
        #endif
        exit(0)
    }
    
    private func invokeAntiDebug() {
        let ptraceName = Obfuscation.decrypt(cipher: [0x5A, 0x53, 0x4B, 0x4E, 0x4F, 0x4B], key: 0x2A) // "ptrace"
        guard let handle = dlopen(nil, RTLD_NOW) else { return }
        defer { dlclose(handle) }
        
        typealias PtraceType = @convention(c) (CInt, pid_t, caddr_t?, CInt) -> CInt
        if let sym = dlsym(handle, ptraceName) {
            let ptraceFunc = unsafeBitCast(sym, to: PtraceType.self)
            _ = ptraceFunc(31 /* PT_DENY_ATTACH */, 0, nil, 0)
        }
    }
    
    private func isDebuggerAttached() -> Bool {
        var info = kinfo_proc()
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var size = MemoryLayout<kinfo_proc>.stride
        let junk = sysctl(&mib, 4, &info, &size, nil, 0)
        if junk == 0 {
            return (info.kp_proc.p_flag & P_TRACED) != 0
        }
        return false
    }
    
    private func detectInjectedLibraries() -> Bool {
        let suspiciousTokens = ["frida", "cynject", "substrate", "substitute", "libhooker", "shadow", "dobby"]
        let count = _dyld_image_count()
        for i in 0..<count {
            if let namePtr = _dyld_get_image_name(i) {
                let name = String(cString: namePtr).lowercased()
                for token in suspiciousTokens {
                    if name.contains(token) {
                        return true
                    }
                }
            }
        }
        return false
    }
    
    private func detectJailbreak() -> Bool {
        let paths = [
            "/Applications/Cydia.app",
            "/Applications/Sileo.app",
            "/Applications/Zebra.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/usr/sbin/sshd",
            "/etc/apt"
        ]
        let fileManager = FileManager.default
        for path in paths {
            if fileManager.fileExists(atPath: path) {
                return true
            }
        }
        if getenv("DYLD_INSERT_LIBRARIES") != nil || getenv("_DYLD_INSERT_LIBRARIES") != nil {
            return true
        }
        return false
    }
    
    public func registerServerSession(key: String, token: String, expiry: String, deviceID: String) {
        var baseSeed: UInt64 = 0x84222325CBF29CE4
        baseSeed = hashField(seed: baseSeed, str: key)
        baseSeed = hashField(seed: baseSeed, str: token)
        baseSeed = hashField(seed: baseSeed, str: expiry)
        baseSeed = hashField(seed: baseSeed, str: deviceID)
        baseSeed ^= 0xA5C3E1F79D4B6028
        
        self.expectedCanary = baseSeed
        self.sessionCanary = baseSeed
    }
    
    public func validateServerSession() -> Bool {
        guard expectedCanary != 0, sessionCanary != 0 else { return false }
        return sessionCanary == expectedCanary
    }
    
    public func invalidateSession() {
        self.sessionCanary = 0
        self.expectedCanary = 0
    }
    
    private func verifyCanaryIntegrity() {
        if sessionCanary != 0 && sessionCanary != expectedCanary {
            triggerTrap()
        }
    }
    
    private func hashField(seed: UInt64, str: String) -> UInt64 {
        var hash = seed
        let prime: UInt64 = 1099511628211
        for byte in str.utf8 {
            hash ^= UInt64(byte)
            hash &*= prime
        }
        return hash
    }
}

public struct Obfuscation {
    public static func decrypt(cipher: [UInt8], key: UInt8) -> String {
        var decoded = [UInt8]()
        for (i, b) in cipher.enumerated() {
            let k = UInt8((Int(key) + (i * 7)) & 0xFF)
            decoded.append(b ^ k)
        }
        return String(bytes: decoded, encoding: .utf8) ?? ""
    }
}
