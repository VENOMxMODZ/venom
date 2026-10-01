//
//  LoginManager.m
//  DefineAura
//
//  Coordinates login authentication flow, session validation, and module startup.
//

#import "LoginManager.h"
#import "SessionManager.h"
#import "ModuleInterface.h"

@interface LoginManager ()
@property (nonatomic, assign, readwrite) BOOL isAuthenticated;
@end

@implementation LoginManager

+ (instancetype)sharedManager {
    static LoginManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[LoginManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _isAuthenticated = NO;
    }
    return self;
}

- (void)loginWithKey:(NSString *)licenseKey {
    NSString *trimmed = [licenseKey stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmed.length == 0) {
        if ([self.delegate respondsToSelector:@selector(loginDidFailWithStatus:message:)]) {
            [self.delegate loginDidFailWithStatus:AuthStatusInvalidKey message:@"License key cannot be empty."];
        }
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(loginDidBeginAuthenticating)]) {
        [self.delegate loginDidBeginAuthenticating];
    }
    
    NSString *deviceID = [[SessionManager sharedManager] getOrCreateDeviceIdentifier];
    
    __weak typeof(self) weakSelf = self;
    [[APIClient sharedClient] authenticateWithLicenseKey:trimmed deviceID:deviceID completion:^(AuthResponse *response) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        
        if (response.status == AuthStatusSuccess) {
            strongSelf.isAuthenticated = YES;
            
            // Persist valid credentials in Keychain
            [[SessionManager sharedManager] saveLicenseKey:trimmed];
            if (response.token) {
                [[SessionManager sharedManager] saveSessionToken:response.token];
            }
            if (response.expiryDate) {
                [[SessionManager sharedManager] saveExpiryDate:response.expiryDate];
            }
            
            // Boot authorized native module
            [[ModuleInterface sharedModule] startModuleWithSessionToken:response.token ?: @""
                                                             licenseKey:trimmed
                                                             expiryDate:response.expiryDate];
            
            if ([strongSelf.delegate respondsToSelector:@selector(loginDidSucceedWithResponse:)]) {
                [strongSelf.delegate loginDidSucceedWithResponse:response];
            }
        } else {
            strongSelf.isAuthenticated = NO;
            if ([strongSelf.delegate respondsToSelector:@selector(loginDidFailWithStatus:message:)]) {
                [strongSelf.delegate loginDidFailWithStatus:response.status message:response.message ?: @"Authentication failed."];
            }
        }
    }];
}

- (void)attemptCachedLogin {
    NSString *savedKey = [[SessionManager sharedManager] getStoredLicenseKey];
    if (savedKey && savedKey.length > 0) {
        [self loginWithKey:savedKey];
    }
}

- (void)logout {
    self.isAuthenticated = NO;
    [[ModuleInterface sharedModule] stopModule];
    [[SessionManager sharedManager] clearAllSessionData];
    NSLog(@"[DefineAura] User logged out and state reset.");
}

@end
