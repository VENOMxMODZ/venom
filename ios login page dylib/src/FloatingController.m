//
//  FloatingController.m
//  DefineAura
//
//  Manages the dedicated floating UI overlay window and touch pass-through.
//

#import "FloatingController.h"
#import "LoginManager.h"
#import "LoginViewController.h"
#import "SecurityHardening.h"

#pragma mark - Pass-Through Overlay Window

@interface FloatingOverlayWindow : UIWindow
@property (nonatomic, weak) FloatingView *targetFloatingView;
@end

@implementation FloatingOverlayWindow

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];
    
    // Only intercept touches that land inside the floating view or its subviews
    if (self.targetFloatingView && !self.targetFloatingView.hidden) {
        CGPoint pointInFloating = [self convertPoint:point toView:self.targetFloatingView];
        if ([self.targetFloatingView pointInside:pointInFloating withEvent:event]) {
            return hitView;
        }
    }
    
    // Pass through all other touches to underlying application / game
    return nil;
}

@end

#pragma mark - Pass-Through Container Controller

@interface FloatingContainerViewController : UIViewController
@end

@implementation FloatingContainerViewController

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

@end

#pragma mark - FloatingController Implementation

@interface FloatingController ()
@property (nonatomic, strong) FloatingOverlayWindow *overlayWindow;
@property (nonatomic, strong, readwrite) FloatingView *floatingView;
@property (nonatomic, assign, readwrite, getter=isVisible) BOOL visible;
@end

@implementation FloatingController

+ (instancetype)sharedController {
    static FloatingController *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FloatingController alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _visible = NO;
    }
    return self;
}

- (void)showFloatingUIWithExpiry:(nullable NSString *)expiry {
    if (!SecurityValidateServerSession()) {
        SecurityTriggerTrap();
        return;
    }
    
    if (self.visible && self.overlayWindow) {
        [self.floatingView updateStatus:@"Active & Authorized" expiry:expiry];
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        CGRect screenBounds = [UIScreen mainScreen].bounds;
        
        // Find active UIWindowScene if iOS 13+
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
                self.overlayWindow = [[FloatingOverlayWindow alloc] initWithWindowScene:activeScene];
            } else {
                self.overlayWindow = [[FloatingOverlayWindow alloc] initWithFrame:screenBounds];
            }
        } else {
            self.overlayWindow = [[FloatingOverlayWindow alloc] initWithFrame:screenBounds];
        }
        
        self.overlayWindow.backgroundColor = [UIColor clearColor];
        self.overlayWindow.windowLevel = UIWindowLevelAlert + 10.0;
        self.overlayWindow.clipsToBounds = NO;
        
        FloatingContainerViewController *rootVC = [[FloatingContainerViewController alloc] init];
        rootVC.view.backgroundColor = [UIColor clearColor];
        self.overlayWindow.rootViewController = rootVC;
        
        self.floatingView = [[FloatingView alloc] initWithFrame:CGRectZero];
        self.floatingView.delegate = self;
        [self.floatingView updateStatus:@"Active & Authorized" expiry:expiry];
        
        [rootVC.view addSubview:self.floatingView];
        self.overlayWindow.targetFloatingView = self.floatingView;
        
        self.overlayWindow.hidden = NO;
        [self.overlayWindow makeKeyAndVisible];
        
        // Animated entrance of floating button
        self.floatingView.alpha = 0.0;
        self.floatingView.transform = CGAffineTransformMakeScale(0.5, 0.5);
        [UIView animateWithDuration:0.35
                              delay:0.0
             usingSpringWithDamping:0.75
              initialSpringVelocity:0.6
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
            self.floatingView.alpha = 1.0;
            self.floatingView.transform = CGAffineTransformIdentity;
        } completion:nil];
        
        self.visible = YES;
    });
}

- (void)hideFloatingUI {
    if (!self.visible) return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.25 animations:^{
            self.floatingView.alpha = 0.0;
            self.floatingView.transform = CGAffineTransformMakeScale(0.5, 0.5);
        } completion:^(BOOL finished) {
            [self.floatingView removeFromSuperview];
            self.floatingView = nil;
            self.overlayWindow.hidden = YES;
            self.overlayWindow = nil;
            self.visible = NO;
        }];
    });
}

#pragma mark - FloatingViewDelegate

- (void)floatingViewDidChangeState:(FloatingViewState)newState {
    NSLog(@"[DefineAura] Floating view switched state to: %ld", (long)newState);
}

- (void)floatingViewDidRequestLogout:(FloatingView *)view {
    [self hideFloatingUI];
    [[LoginManager sharedManager] logout];
    
    // Notify host or re-show login window
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DefineAuraDidRequestLoginNotification" object:nil];
}

@end
