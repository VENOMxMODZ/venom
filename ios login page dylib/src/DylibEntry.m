//
//  DylibEntry.m
//  DefineAura
//
//  Dynamic Library Entry Point and Lifecycle Coordinator.
//  Injected automatically when the host app loads the dylib.
//

#import <UIKit/UIKit.h>
#import "LoginViewController.h"
#import "FloatingController.h"
#import "LoginManager.h"
#import "SessionManager.h"
#import "ModuleInterface.h"

static UIWindow *sLoginWindow = nil;

static void PresentLoginInterface(void) {
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
        
        // Success handler: dismiss login window completely and reveal floating UI
        loginVC.onLoginSuccess = ^{
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
    NSLog(@"[DefineAura] Dynamic Library successfully injected. Initializing security handshake...");
    
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
    // Check if application is already initialized or wait for didFinishLaunching
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
