//
//  SessionManager.h
//  DefineAura
//
//  Secure Keychain Storage and Session State Manager
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SessionManager : NSObject

+ (instancetype)sharedManager;

/// Persistent Hardware / Unique Device Identifier anchored in Keychain
- (NSString *)getOrCreateDeviceIdentifier;

/// License Key Keychain management
- (BOOL)saveLicenseKey:(NSString *)licenseKey;
- (nullable NSString *)getStoredLicenseKey;
- (BOOL)clearStoredLicenseKey;

/// Session Token Keychain management
- (BOOL)saveSessionToken:(NSString *)token;
- (nullable NSString *)getStoredSessionToken;
- (BOOL)clearStoredSessionToken;

/// Session Expiration Metadata
- (void)saveExpiryDate:(NSString *)expiryDate;
- (nullable NSString *)getStoredExpiryDate;

/// Clear all stored credentials and session data
- (void)clearAllSessionData;

@end

NS_ASSUME_NONNULL_END
