//
//  FloatingView.h
//  DefineAura
//
//  Draggable, compact floating UI element capable of minimizing into a small
//  floating button and expanding into a sleek control panel.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, FloatingViewState) {
    FloatingViewStateMinimized = 0,
    FloatingViewStateExpanded
};

@class FloatingView;

@protocol FloatingViewDelegate <NSObject>
@optional
- (void)floatingViewDidChangeState:(FloatingViewState)newState;
- (void)floatingViewDidRequestLogout:(FloatingView *)view;
@end

@interface FloatingView : UIView

@property (nonatomic, weak, nullable) id<FloatingViewDelegate> delegate;
@property (nonatomic, readonly) FloatingViewState currentState;

- (instancetype)initWithFrame:(CGRect)frame;

/// Updates the displayed status or expiry information
- (void)updateStatus:(NSString *)statusText expiry:(nullable NSString *)expiryText;

/// Programmatically toggle or set expansion state
- (void)setExpanded:(BOOL)expanded animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
