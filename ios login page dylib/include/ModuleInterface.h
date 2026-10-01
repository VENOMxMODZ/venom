//
//  ModuleInterface.h
//  DefineAura
//
//  Decoupled interface for the authorized native application module.
//  Keeps authentication completely separated from module payload logic.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ModuleInterfaceDelegate <NSObject>
@optional
- (void)moduleDidUpdateStatus:(NSString *)statusMessage;
- (void)moduleDidEncounterError:(NSError *)error;
@end

@interface ModuleInterface : NSObject

@property (nonatomic, weak, nullable) id<ModuleInterfaceDelegate> delegate;
@property (nonatomic, readonly, getter=isAuthorized) BOOL authorized;
@property (nonatomic, readonly, getter=isRunning) BOOL running;

+ (instancetype)sharedModule;

/// Initialize and start the authorized module payload after valid authentication
- (void)startModuleWithSessionToken:(NSString *)token
                         licenseKey:(NSString *)licenseKey
                         expiryDate:(nullable NSString *)expiryDate;

/// Stop/deactivate the module payload
- (void)stopModule;

/// Perform authorized module action or hook
- (void)executeFeatureActionNamed:(NSString *)featureName parameters:(nullable NSDictionary *)params;

@end

NS_ASSUME_NONNULL_END
