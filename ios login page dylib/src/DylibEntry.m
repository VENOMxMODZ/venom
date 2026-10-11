//
//  DylibEntry.m
//  DefineAura
//
//  Dynamic Library Entry Point and Lifecycle Coordinator.
//  Injected automatically when the host app loads the dylib.
//  Hardened with immediate anti-tamper initialization and sentinel watchdog.
//

#import <UIKit/UIKit.h>
#import "LoginViewController.h"
#import "FloatingController.h"
#import "LoginManager.h"
#import "SessionManager.h"
#import "ModuleInterface.h"
#import "SecurityHardening.h"

static UIWindow *sLoginWindow = nil;

static void PresentLoginInterface(void) {
    SecurityEnforceOrTerminate();
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (sLoginWindow) return;
        
        CGRect screenBounds = [UIScreen mainScreen].bounds;
        
        UIWindowScene *activeScene = nil;
        if (@available(iOS 13.0, *)) {
            for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:[UIWindowScene class]]) {
                    activeScene = (UIWindowScene *)scene;
                    break;
                }
            }
        }
        
        if (@available(iOS 13.0, *)) {
            if (activeScene) {
                sLoginWindow = [[UIWindow alloc] initWithWindowScene:activeScene];
            } else {
                sLoginWindow = [[UIWindow alloc] initWithFrame:screenBounds];
            }
        } else {
            sLoginWindow = [[UIWindow alloc] initWithFrame:screenBounds];
        }
        
        sLoginWindow.windowLevel = UIWindowLevelAlert + 5.0;
        sLoginWindow.backgroundColor = [UIColor clearColor];
        
        LoginViewController *loginVC = [[LoginViewController alloc] init];
        
        // Success handler: dismiss login window and reveal floating UI only if server verified
        loginVC.onLoginSuccess = ^{
            // Verify that the server genuinely issued this authorization
            if (!SecurityValidateServerSession()) {
                SecurityTriggerTrap();
                return;
            }
            
            sLoginWindow.hidden = YES;
            sLoginWindow = nil;
            
            // Retrieve session expiry if available
            NSString *expiry = [[SessionManager sharedManager] getStoredExpiryDate];
            [[FloatingController sharedController] showFloatingUIWithExpiry:expiry];
        };
        
        sLoginWindow.rootViewController = loginVC;
        sLoginWindow.hidden = NO;
        [sLoginWindow makeKeyAndVisible];
    });
}

static void InitializeDefineAura(void) {
    // Continuous integrity check
    SecurityEnforceOrTerminate();
    
    // Register for logout / relogin requests
    [[NSNotificationCenter defaultCenter] addObserverForName:@"DefineAuraDidRequestLoginNotification"
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        PresentLoginInterface();
    }];
    
    // Delay slightly to ensure host app UI hierarchy and scenes are established
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        PresentLoginInterface();
    });
}

// Dynamic library constructor
__attribute__((constructor)) static void EntryPoint(void) {
    // 1. Immediately activate anti-debug, anti-Frida, and anti-tamper protections
    SecurityHardeningInit();
    
    // 2. Check if application is already initialized or wait for didFinishLaunching
    if ([UIApplication sharedApplication] != nil) {
        InitializeDefineAura();
    } else {
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification * _Nonnull note) {
            InitializeDefineAura();
        }];
    }
}
