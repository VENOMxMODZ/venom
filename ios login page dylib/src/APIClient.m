//
//  APIClient.m
//  DefineAura
//
//  Secure HTTPS Client for VenomPanel Authentication API
//

#import "APIClient.h"

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

@interface APIClient ()
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
        _endpointURL = @"https://venompanel.shop/rootapi";
        _gameName = @"DefineAura";
        
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        config.timeoutIntervalForRequest = 15.0;
        config.timeoutIntervalForResource = 30.0;
        config.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        _urlSession = [NSURLSession sessionWithConfiguration:config];
    }
    return self;
}

- (void)authenticateWithLicenseKey:(NSString *)licenseKey
                          deviceID:(NSString *)deviceID
                        completion:(AuthCompletionHandler)completion {
    
    // Clean key string
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
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"DefineAura/1.0 (iOS)" forHTTPHeaderField:@"User-Agent"];
    
    // Formulate payload - zero admin credentials embedded
    NSDictionary *payload = @{
        @"game": self.gameName,
        @"key": trimmedKey,
        @"device_id": deviceID ?: @"",
        @"platform": @"iOS"
    };
    
    NSError *jsonError = nil;
    NSData *bodyData = [NSJSONSerialization dataWithJSONObject:payload options:0 error:&jsonError];
    if (jsonError || !bodyData) {
        dispatch_async(dispatch_get_main_queue(), ^{
            AuthResponse *res = [[AuthResponse alloc] initWithStatus:AuthStatusServerError
                                                            message:@"Failed to serialize authentication payload."];
            completion(res);
        });
        return;
    }
    
    [request setHTTPBody:bodyData];
    
    NSURLSessionDataTask *task = [self.urlSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *msg = [NSString stringWithFormat:@"Network connection error: %@", error.localizedDescription];
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
        
        // Parse JSON response
        NSError *parseError = nil;
        id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
        
        if (parseError || ![json isKindOfClass:[NSDictionary class]]) {
            // Attempt to read plain string if server sent non-json text
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
        AuthResponse *authResponse = [self parseAuthDictionary:dict statusCode:statusCode];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(authResponse);
        });
    }];
    
    [task resume];
}

- (AuthResponse *)parseAuthDictionary:(NSDictionary *)dict statusCode:(NSInteger)statusCode {
    AuthResponse *res = [[AuthResponse alloc] init];
    res.rawPayload = dict;
    
    // Status can be string "success", boolean true, or integer 200/1
    id statusVal = dict[@"status"] ?: dict[@"result"] ?: dict[@"success"];
    id msgVal = dict[@"message"] ?: dict[@"msg"] ?: dict[@"error"] ?: dict[@"reason"];
    id expiryVal = dict[@"expiry"] ?: dict[@"expiry_date"] ?: dict[@"expire"] ?: dict[@"expires"];
    id tokenVal = dict[@"token"] ?: dict[@"session_token"] ?: dict[@"auth_token"];
    
    NSString *message = [msgVal isKindOfClass:[NSString class]] ? (NSString *)msgVal : @"";
    NSString *expiryStr = [expiryVal isKindOfClass:[NSString class]] ? (NSString *)expiryVal : [expiryVal description];
    NSString *tokenStr = [tokenVal isKindOfClass:[NSString class]] ? (NSString *)tokenVal : nil;
    
    res.expiryDate = expiryStr;
    res.token = tokenStr;
    res.message = message;
    
    BOOL isSuccess = NO;
    if ([statusVal isKindOfClass:[NSString class]]) {
        NSString *s = [(NSString *)statusVal lowercaseString];
        if ([s isEqualToString:@"success"] || [s isEqualToString:@"true"] || [s isEqualToString:@"ok"] || [s isEqualToString:@"1"]) {
            isSuccess = YES;
        }
    } else if ([statusVal isKindOfClass:[NSNumber class]]) {
        isSuccess = [statusVal boolValue] || [statusVal integerValue] == 200 || [statusVal integerValue] == 1;
    }
    
    if (isSuccess && statusCode == 200) {
        res.status = AuthStatusSuccess;
        if (res.message.length == 0) {
            res.message = @"Authentication successful!";
        }
        return res;
    }
    
    // Determine exact failure category
    NSString *combinedText = [NSString stringWithFormat:@"%@ %@", [statusVal description] ?: @"", message].lowercaseString;
    
    if ([combinedText containsString:@"expired"] || [combinedText containsString:@"out of date"]) {
        res.status = AuthStatusExpiredKey;
        res.message = message.length > 0 ? message : @"This license key has expired.";
    } else if ([combinedText containsString:@"invalid"] || [combinedText containsString:@"not found"] || [combinedText containsString:@"wrong"] || [combinedText containsString:@"unauthorized"]) {
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
