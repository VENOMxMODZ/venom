//
//  SessionManager.m
//  DefineAura
//
//  Secure Keychain Storage and Session State Manager
//

#import "SessionManager.h"
#import <Security/Security.h>
#import <UIKit/UIKit.h>

static NSString * const kServiceIdentifier = @"com.defineaura.auth";
static NSString * const kKeyDeviceUUID     = @"deviceID";
static NSString * const kKeyLicenseKey     = @"licenseKey";
static NSString * const kKeySessionToken   = @"sessionToken";
static NSString * const kKeyExpiryDate     = @"expiryDate";

@implementation SessionManager

+ (instancetype)sharedManager {
    static SessionManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SessionManager alloc] init];
    });
    return instance;
}

#pragma mark - Keychain Low-Level Helpers

- (BOOL)keychainSaveString:(NSString *)string forKey:(NSString *)key {
    if (!string || !key) return NO;
    
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    
    // Check if item exists first
    NSDictionary *searchQuery = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: kServiceIdentifier,
        (__bridge id)kSecAttrAccount: key
    };
    
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)searchQuery, NULL);
    
    if (status == errSecSuccess) {
        // Update existing item
        NSDictionary *updateQuery = @{
            (__bridge id)kSecValueData: data,
            (__bridge id)kSecAttrAccessible: (__bridge id)kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        };
        OSStatus updateStatus = SecItemUpdate((__bridge CFDictionaryRef)searchQuery, (__bridge CFDictionaryRef)updateQuery);
        return (updateStatus == errSecSuccess);
    } else if (status == errSecItemNotFound) {
        // Insert new item
        NSMutableDictionary *newQuery = [searchQuery mutableCopy];
        newQuery[(__bridge id)kSecValueData] = data;
        newQuery[(__bridge id)kSecAttrAccessible] = (__bridge id)kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly;
        
        OSStatus addStatus = SecItemAdd((__bridge CFDictionaryRef)newQuery, NULL);
        return (addStatus == errSecSuccess);
    }
    
    return NO;
}

- (nullable NSString *)keychainGetStringForKey:(NSString *)key {
    if (!key) return nil;
    
    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: kServiceIdentifier,
        (__bridge id)kSecAttrAccount: key,
        (__bridge id)kSecReturnData: @YES,
        (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitOne
    };
    
    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
    
    if (status == errSecSuccess && result != NULL) {
        NSData *data = (__bridge_transfer NSData *)result;
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    
    return nil;
}

- (BOOL)keychainDeleteKey:(NSString *)key {
    if (!key) return NO;
    
    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: kServiceIdentifier,
        (__bridge id)kSecAttrAccount: key
    };
    
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)query);
    return (status == errSecSuccess || status == errSecItemNotFound);
}

#pragma mark - Public Interface

- (NSString *)getOrCreateDeviceIdentifier {
    NSString *existingUUID = [self keychainGetStringForKey:kKeyDeviceUUID];
    if (existingUUID && existingUUID.length > 0) {
        return existingUUID;
    }
    
    // Generate new Hardware / Device identifier
    NSString *newUUID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    if (!newUUID || newUUID.length == 0) {
        newUUID = [[NSUUID UUID] UUIDString];
    }
    
    [self keychainSaveString:newUUID forKey:kKeyDeviceUUID];
    return newUUID;
}

- (BOOL)saveLicenseKey:(NSString *)licenseKey {
    return [self keychainSaveString:licenseKey forKey:kKeyLicenseKey];
}

- (nullable NSString *)getStoredLicenseKey {
    return [self keychainGetStringForKey:kKeyLicenseKey];
}

- (BOOL)clearStoredLicenseKey {
    return [self keychainDeleteKey:kKeyLicenseKey];
}

- (BOOL)saveSessionToken:(NSString *)token {
    return [self keychainSaveString:token forKey:kKeySessionToken];
}

- (nullable NSString *)getStoredSessionToken {
    return [self keychainGetStringForKey:kKeySessionToken];
}

- (BOOL)clearStoredSessionToken {
    return [self keychainDeleteKey:kKeySessionToken];
}

- (void)saveExpiryDate:(NSString *)expiryDate {
    [self keychainSaveString:expiryDate forKey:kKeyExpiryDate];
}

- (nullable NSString *)getStoredExpiryDate {
    return [self keychainGetStringForKey:kKeyExpiryDate];
}

- (void)clearAllSessionData {
    [self clearStoredLicenseKey];
    [self clearStoredSessionToken];
    [self keychainDeleteKey:kKeyExpiryDate];
}

@end
