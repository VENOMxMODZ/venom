//
//  ModuleInterface.m
//  DefineAura
//
//  Decoupled interface for the authorized native application module.
//  Protected by inlined cryptographic server session validation & anti-crack sentinels.
//

#import "ModuleInterface.h"
#import "SecurityHardening.h"

@interface ModuleInterface ()
@property (nonatomic, assign, readwrite) BOOL authorized;
@property (nonatomic, assign, readwrite, getter=isRunning) BOOL running;
@property (nonatomic, copy, nullable) NSString *currentSessionToken;
@property (nonatomic, copy, nullable) NSString *currentLicenseKey;
@property (nonatomic, copy, nullable) NSString *currentExpiryDate;
@end

@implementation ModuleInterface

+ (instancetype)sharedModule {
    static ModuleInterface *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ModuleInterface alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _authorized = NO;
        _running = NO;
    }
    return self;
}

- (BOOL)isAuthorized {
    // Multi-layered authorization check:
    // Requires both internal flag AND cryptographic server session canary
    if (!_authorized) {
        return NO;
    }
    
    if (!SecurityValidateServerSession()) {
        // Cracking/tampering detected: local flag set without valid server handshake!
        SecurityTriggerTrap();
        return NO;
    }
    
    return YES;
}

- (void)startModuleWithSessionToken:(NSString *)token
                         licenseKey:(NSString *)licenseKey
                         expiryDate:(nullable NSString *)expiryDate {
    
    // Continuous environment verification
    SecurityEnforceOrTerminate();
    
    // Verify that the server actually validated this session cryptographically
    if (!SecurityValidateServerSession()) {
        // Attacker attempted to bypass authentication by calling startModule directly
        SecurityTriggerTrap();
        return;
    }
    
    if (token.length == 0 && licenseKey.length == 0) {
        SecurityTriggerTrap();
        return;
    }
    
    self.authorized = YES;
    self.currentSessionToken = token;
    self.currentLicenseKey = licenseKey;
    self.currentExpiryDate = expiryDate;
    self.running = YES;
    
    if ([self.delegate respondsToSelector:@selector(moduleDidUpdateStatus:)]) {
        [self.delegate moduleDidUpdateStatus:@"Module Active & Synchronized"];
    }
}

- (void)stopModule {
    self.running = NO;
    self.authorized = NO;
    self.currentSessionToken = nil;
    self.currentLicenseKey = nil;
    self.currentExpiryDate = nil;
    
    SecurityInvalidateSession();
    
    if ([self.delegate respondsToSelector:@selector(moduleDidUpdateStatus:)]) {
        [self.delegate moduleDidUpdateStatus:@"Module Deactivated"];
    }
}

- (void)executeFeatureActionNamed:(NSString *)featureName parameters:(nullable NSDictionary *)params {
    SecurityEnforceOrTerminate();
    
    if (!self.isAuthorized || !self.running) {
        SecurityTriggerTrap();
        return;
    }
    
    // Core payload execution protected by verified server session
}

@end
