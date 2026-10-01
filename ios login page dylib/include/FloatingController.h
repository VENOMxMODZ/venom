//
//  FloatingController.h
//  DefineAura
//
//  Manages the dedicated floating UI overlay window and touch pass-through.
//  Ensures the floating view is completely hidden until authentication succeeds.
//

#import <UIKit/UIKit.h>
#import "FloatingView.h"

NS_ASSUME_NONNULL_BEGIN

@interface FloatingController : NSObject <FloatingViewDelegate>

@property (nonatomic, strong, readonly) FloatingView *floatingView;
@property (nonatomic, readonly, getter=isVisible) BOOL visible;

+ (instancetype)sharedController;

/// Mounts and displays the floating UI after successful authentication
- (void)showFloatingUIWithExpiry:(nullable NSString *)expiry;

/// Hides and destroys the floating UI overlay
- (void)hideFloatingUI;

@end

NS_ASSUME_NONNULL_END
