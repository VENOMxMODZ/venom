//
//  LoginManager.h
//  DefineAura
//
//  Coordinates login authentication flow, session validation, and module startup.
//

#import <Foundation/Foundation.h>
#import "APIClient.h"

NS_ASSUME_NONNULL_BEGIN

@protocol LoginManagerDelegate <NSObject>
@required
- (void)loginDidSucceedWithResponse:(AuthResponse *)response;
- (void)loginDidFailWithStatus:(AuthStatus)status message:(NSString *)errorMessage;
@optional
- (void)loginDidBeginAuthenticating;
@end

@interface LoginManager : NSObject

@property (nonatomic, weak, nullable) id<LoginManagerDelegate> delegate;
@property (nonatomic, readonly) BOOL isAuthenticated;

+ (instancetype)sharedManager;

/// Initiates login with the provided license key
- (void)loginWithKey:(NSString *)licenseKey;

/// Check and attempt automatic login using saved key
- (void)attemptCachedLogin;

/// Logs out, clears sessions, and resets module state
- (void)logout;

@end

NS_ASSUME_NONNULL_END
