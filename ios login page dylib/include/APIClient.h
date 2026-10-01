//
//  APIClient.h
//  DefineAura
//
//  Secure HTTPS Client for VenomPanel Authentication API
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, AuthStatus) {
    AuthStatusSuccess = 0,
    AuthStatusInvalidKey,
    AuthStatusExpiredKey,
    AuthStatusNetworkError,
    AuthStatusServerError,
    AuthStatusUnknownError
};

@interface AuthResponse : NSObject

@property (nonatomic, assign) AuthStatus status;
@property (nonatomic, copy, nullable) NSString *token;
@property (nonatomic, copy, nullable) NSString *expiryDate;
@property (nonatomic, copy, nullable) NSString *message;
@property (nonatomic, strong, nullable) NSDictionary *rawPayload;

- (instancetype)initWithStatus:(AuthStatus)status message:(nullable NSString *)message;

@end

typedef void (^AuthCompletionHandler)(AuthResponse *response);

@interface APIClient : NSObject

@property (nonatomic, copy) NSString *endpointURL;
@property (nonatomic, copy) NSString *gameName;

+ (instancetype)sharedClient;

- (void)authenticateWithLicenseKey:(NSString *)licenseKey
                          deviceID:(NSString *)deviceID
                        completion:(AuthCompletionHandler)completion;

@end

NS_ASSUME_NONNULL_END
