//
//  LoginViewController.h
//  DefineAura
//
//  Professional dark login interface with custom styling, validation alerts,
//  and animated dismissal.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^LoginSuccessCompletion)(void);

@interface LoginViewController : UIViewController

/// Callback triggered when authentication successfully finishes and transition starts
@property (nonatomic, copy, nullable) LoginSuccessCompletion onLoginSuccess;

/// Dismiss the login view controller with a smooth transition
- (void)dismissWithSuccessAnimation:(void (^ _Nullable)(void))completion;

@end

NS_ASSUME_NONNULL_END
