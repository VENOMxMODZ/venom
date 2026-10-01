//
//  ModuleInterface.m
//  DefineAura
//
//  Decoupled interface for the authorized native application module.
//

#import "ModuleInterface.h"

@interface ModuleInterface ()
@property (nonatomic, assign, readwrite, getter=isAuthorized) BOOL authorized;
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

- (void)startModuleWithSessionToken:(NSString *)token
                         licenseKey:(NSString *)licenseKey
                         expiryDate:(nullable NSString *)expiryDate {
    if (token.length == 0 && licenseKey.length == 0) {
        NSLog(@"[DefineAura] Unauthorized module startup attempt blocked.");
        return;
    }
    
    self.authorized = YES;
    self.currentSessionToken = token;
    self.currentLicenseKey = licenseKey;
    self.currentExpiryDate = expiryDate;
    self.running = YES;
    
    NSLog(@"[DefineAura] Authorized module initialized successfully. Expiry: %@", expiryDate ?: @"N/A");
    
    // Notify delegate if set
    if ([self.delegate respondsToSelector:@selector(moduleDidUpdateStatus:)]) {
        [self.delegate moduleDidUpdateStatus:@"Module Active & Synchronized"];
    }
    
    // Here you can hook internal engine callbacks, allocate memory buffers, or register game observation hooks
}

- (void)stopModule {
    self.running = NO;
    self.authorized = NO;
    self.currentSessionToken = nil;
    self.currentLicenseKey = nil;
    self.currentExpiryDate = nil;
    
    NSLog(@"[DefineAura] Authorized module stopped and session purged.");
    
    if ([self.delegate respondsToSelector:@selector(moduleDidUpdateStatus:)]) {
        [self.delegate moduleDidUpdateStatus:@"Module Deactivated"];
    }
}

- (void)executeFeatureActionNamed:(NSString *)featureName parameters:(nullable NSDictionary *)params {
    if (!self.authorized || !self.running) {
        NSLog(@"[DefineAura] Action '%@' blocked: Module is not authorized.", featureName);
        return;
    }
    
    NSLog(@"[DefineAura] Executing authorized feature action: %@ with params: %@", featureName, params);
}

@end
