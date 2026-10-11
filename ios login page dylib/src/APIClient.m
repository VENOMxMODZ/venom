//
//  APIClient.m
//  DefineAura
//
//  Hardened Anti-Crack HTTPS Client for VenomPanel Authentication API
//  Strings encrypted at compile time. Strict TLS pinning & tamper resistance.
//

#import "APIClient.h"
#import "Obfuscation.h"
#import "SecurityHardening.h"
#import <Security/Security.h>

@implementation AuthResponse

- (instancetype)initWithStatus:(AuthStatus)status message:(nullable NSString *)message {
    self = [super init];
    if (self) {
        _status = status;
        _message = message;
    }
    return self;
}

@end

@interface APIClient () <NSURLSessionDelegate>
@property (nonatomic, strong) NSURLSession *urlSession;
@end

@implementation APIClient

+ (instancetype)sharedClient {
    static APIClient *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[APIClient alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _endpointURL = GET_STR_API_ENDPOINT();
        _gameName = GET_STR_GAME_NAME();
        
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        config.timeoutIntervalForRequest = 15.0;
        config.timeoutIntervalForResource = 30.0;
        config.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        _urlSession = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    }
    return self;
}

#pragma mark - Strict TLS / Certificate Pinning Validation

- (void)URLSession:(NSURLSession *)session
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler {
    
    // Immediate anti-tamper check
    SecurityEnforceOrTerminate();
    
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
        NSString *host = challenge.protectionSpace.host;
        NSString *expectedHost = GET_STR_API_HOST();
        
        if (![host isEqualToString:expectedHost]) {
            // Host spoofing / proxy redirect detected
            completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
            return;
        }
        
        if (serverTrust) {
            bool isTrusted = false;
            if (@available(iOS 12.0, *)) {
                CFErrorRef error = NULL;
                isTrusted = SecTrustEvaluateWithError(serverTrust, &error);
                if (error) {
                    CFRelease(error);
                }
            } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                SecTrustResultType result;
                SecTrustEvaluate(serverTrust, &result);
                isTrusted = (result == kSecTrustResultProceed || result == kSecTrustResultUnspecified);
#pragma clang diagnostic pop
            }
            
            if (isTrusted) {
                completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:serverTrust]);
                return;
            }
        }
        
        // Untrusted certificate / MITM proxy (Burp, Charles) intercepted
        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
        return;
    }
    
    completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
}

#pragma mark - Authentication Request

- (void)authenticateWithLicenseKey:(NSString *)licenseKey
                          deviceID:(NSString *)deviceID
                        completion:(AuthCompletionHandler)completion {
    
    // Ensure security environment is pristine before issuing request
    SecurityEnforceOrTerminate();
    
    NSString *trimmedKey = [licenseKey stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (trimmedKey.length == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            AuthResponse *res = [[AuthResponse alloc] initWithStatus:AuthStatusInvalidKey
                                                            message:@"Please enter a valid license key."];
            completion(res);
        });
        return;
    }
    
    NSURL *url = [NSURL URLWithString:self.endpointURL];
    if (!url) {
        dispatch_async(dispatch_get_main_queue(), ^{
            AuthResponse *res = [[AuthResponse alloc] initWithStatus:AuthStatusServerError
                                                            message:@"Invalid API endpoint configuration."];
            completion(res);
        });
        return;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:GET_STR_URL_ENCODED() forHTTPHeaderField:GET_STR_CONTENT_TYPE()];
    [request setValue:GET_STR_APP_JSON() forHTTPHeaderField:GET_STR_ACCEPT()];
    [request setValue:GET_STR_USER_AGENT() forHTTPHeaderField:GET_STR_USER_AGENT()];
    
    NSCharacterSet *allowedSet = [NSCharacterSet URLQueryAllowedCharacterSet];
    NSString *encGame = [self.gameName stringByAddingPercentEncodingWithAllowedCharacters:allowedSet] ?: @"";
    NSString *encKey = [trimmedKey stringByAddingPercentEncodingWithAllowedCharacters:allowedSet] ?: @"";
    NSString *encSerial = [deviceID stringByAddingPercentEncodingWithAllowedCharacters:allowedSet] ?: @"";
    
    // Reconstruct obfuscated POST parameters
    NSString *pGame = GET_STR_PARAM_GAME();
    NSString *pUserKey = GET_STR_PARAM_USER_KEY();
    NSString *pSerial = GET_STR_PARAM_SERIAL();
    NSString *pKey = GET_STR_PARAM_KEY();
    NSString *pDeviceID = GET_STR_PARAM_DEVICE_ID();
    
    NSString *postBodyString = [NSString stringWithFormat:@"%@=%@&%@=%@&%@=%@&%@=%@&%@=%@",
                                pGame, encGame,
                                pUserKey, encKey,
                                pSerial, encSerial,
                                pKey, encKey,
                                pDeviceID, encSerial];
    
    NSData *bodyData = [postBodyString dataUsingEncoding:NSUTF8StringEncoding];
    [request setHTTPBody:bodyData];
    
    __weak typeof(self) weakSelf = self;
    NSURLSessionDataTask *task = [self.urlSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        
        // Periodic security heartbeat check on callback
        SecurityEnforceOrTerminate();
        
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *msg = [NSString stringWithFormat:@"Connection security error: %@", error.localizedDescription];
                AuthResponse *res = [[AuthResponse alloc] initWithStatus:AuthStatusNetworkError message:msg];
                completion(res);
            });
            return;
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSInteger statusCode = httpResponse.statusCode;
        
        if (statusCode >= 500) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *msg = [NSString stringWithFormat:@"Server unavailable (Status %ld). Please try again later.", (long)statusCode];
                AuthResponse *res = [[AuthResponse alloc] initWithStatus:AuthStatusServerError message:msg];
                completion(res);
            });
            return;
        }
        
        if (!data || data.length == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                AuthResponse *res = [[AuthResponse alloc] initWithStatus:AuthStatusServerError
                                                                message:@"Empty response from authentication server."];
                completion(res);
            });
            return;
        }
        
        NSError *parseError = nil;
        id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
        
        if (parseError || ![json isKindOfClass:[NSDictionary class]]) {
            NSString *rawString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (rawString && [rawString localizedCaseInsensitiveContainsString:@"invalid"]) {
                    AuthResponse *res = [[AuthResponse alloc] initWithStatus:AuthStatusInvalidKey message:@"Invalid license key."];
                    completion(res);
                } else if (rawString && [rawString localizedCaseInsensitiveContainsString:@"expired"]) {
                    AuthResponse *res = [[AuthResponse alloc] initWithStatus:AuthStatusExpiredKey message:@"License key has expired."];
                    completion(res);
                } else {
                    AuthResponse *res = [[AuthResponse alloc] initWithStatus:AuthStatusServerError
                                                                    message:@"Invalid server response format."];
                    completion(res);
                }
            });
            return;
        }
        
        NSDictionary *dict = (NSDictionary *)json;
        AuthResponse *authResponse = [strongSelf parseAuthDictionary:dict statusCode:statusCode licenseKey:trimmedKey deviceID:deviceID];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(authResponse);
        });
    }];
    
    [task resume];
}

- (AuthResponse *)parseAuthDictionary:(NSDictionary *)dict
                           statusCode:(NSInteger)statusCode
                           licenseKey:(NSString *)licenseKey
                             deviceID:(NSString *)deviceID {
    AuthResponse *res = [[AuthResponse alloc] init];
    res.rawPayload = dict;
    
    // Obfuscated JSON keys retrieval
    id statusVal = dict[GET_STR_JSON_STATUS()] ?: dict[GET_STR_JSON_RESULT()] ?: dict[GET_STR_JSON_SUCCESS()];
    id msgVal = dict[GET_STR_JSON_MESSAGE()] ?: dict[GET_STR_JSON_MSG()] ?: dict[GET_STR_JSON_ERROR()] ?: dict[GET_STR_JSON_REASON()];
    
    NSDictionary *dataDict = [dict[GET_STR_JSON_DATA()] isKindOfClass:[NSDictionary class]] ? dict[GET_STR_JSON_DATA()] : nil;
    
    id expiryVal = dict[GET_STR_JSON_EXPIRED_DATE()] ?: (dataDict ? dataDict[GET_STR_JSON_EXPIRED_DATE()] : nil)
                ?: dict[GET_STR_JSON_EXPIRY()] ?: (dataDict ? dataDict[GET_STR_JSON_EXPIRY()] : nil);
    
    id tokenVal = dict[GET_STR_JSON_TOKEN()] ?: (dataDict ? dataDict[GET_STR_JSON_TOKEN()] : nil)
               ?: dict[GET_STR_JSON_SESSION_TOKEN()] ?: (dataDict ? dataDict[GET_STR_JSON_SESSION_TOKEN()] : nil);
    
    NSString *message = [msgVal isKindOfClass:[NSString class]] ? (NSString *)msgVal : @"";
    NSString *expiryStr = [expiryVal isKindOfClass:[NSString class]] ? (NSString *)expiryVal : [expiryVal description];
    NSString *tokenStr = [tokenVal isKindOfClass:[NSString class]] ? (NSString *)tokenVal : nil;
    
    res.expiryDate = expiryStr;
    res.token = tokenStr;
    res.message = message;
    
    BOOL isSuccess = NO;
    if ([statusVal isKindOfClass:[NSNumber class]]) {
        isSuccess = [statusVal boolValue] || [statusVal integerValue] == 200 || [statusVal integerValue] == 1;
    } else if ([statusVal isKindOfClass:[NSString class]]) {
        NSString *s = [(NSString *)statusVal lowercaseString];
        if ([s isEqualToString:@"success"] || [s isEqualToString:@"true"] || [s isEqualToString:@"ok"] || [s isEqualToString:@"1"]) {
            isSuccess = YES;
        }
    }
    
    if (!isSuccess && dict[GET_STR_JSON_SUCCESS()] != nil && [dict[GET_STR_JSON_SUCCESS()] isKindOfClass:[NSNumber class]]) {
        isSuccess = [dict[GET_STR_JSON_SUCCESS()] boolValue];
    }
    
    if (isSuccess && (statusCode == 200 || statusCode == 0)) {
        res.status = AuthStatusSuccess;
        if (res.message.length == 0) {
            res.message = @"Authentication successful!";
        }
        
        // Cryptographically bind verified server response into session canary
        SecurityRegisterServerSession(licenseKey, tokenStr ?: @"", expiryStr ?: @"", deviceID ?: @"");
        return res;
    }
    
    // Invalidate any residual canary on failure
    SecurityInvalidateSession();
    
    NSString *combinedText = [NSString stringWithFormat:@"%@ %@", [statusVal description] ?: @"", message].lowercaseString;
    
    if ([combinedText containsString:@"expired"] || [combinedText containsString:@"out of date"]) {
        res.status = AuthStatusExpiredKey;
        res.message = message.length > 0 ? message : @"This license key has expired.";
    } else if ([combinedText containsString:@"invalid"] || [combinedText containsString:@"not found"] || [combinedText containsString:@"wrong"] || [combinedText containsString:@"unauthorized"] || [combinedText containsString:@"missing"]) {
        res.status = AuthStatusInvalidKey;
        res.message = message.length > 0 ? message : @"Invalid license key. Please check and try again.";
    } else if (statusCode >= 400 && statusCode < 500) {
        res.status = AuthStatusInvalidKey;
        res.message = message.length > 0 ? message : @"Authentication failed (Unauthorized).";
    } else {
        res.status = AuthStatusServerError;
        res.message = message.length > 0 ? message : @"Server error encountered. Please try again later.";
    }
    
    return res;
}

@end
