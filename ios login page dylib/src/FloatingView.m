//
//  FloatingView.m
//  DefineAura
//
//  Draggable, compact floating UI element capable of minimizing into a small
//  floating button and expanding into a sleek control panel.
//

#import "FloatingView.h"
#import "ModuleInterface.h"

static const CGFloat kMinimizedSize = 52.0;
static const CGFloat kExpandedWidth = 240.0;
static const CGFloat kExpandedHeight = 260.0;

@interface FloatingView ()

@property (nonatomic, assign, readwrite) FloatingViewState currentState;
@property (nonatomic, assign) CGPoint touchOffset;

// Minimized components
@property (nonatomic, strong) UIView *minimizedContainer;
@property (nonatomic, strong) UILabel *minimizedBadgeLabel;
@property (nonatomic, strong) UIView *minimizedStatusDot;

// Expanded components
@property (nonatomic, strong) UIView *expandedContainer;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UILabel *expiryLabel;
@property (nonatomic, strong) UISwitch *moduleSwitch;
@property (nonatomic, strong) UIButton *minimizeButton;
@property (nonatomic, strong) UIButton *logoutButton;

@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;

@end

@implementation FloatingView

- (instancetype)initWithFrame:(CGRect)frame {
    // Default initial frame positioned comfortably in top right
    CGRect initialFrame = CGRectMake([UIScreen mainScreen].bounds.size.width - kMinimizedSize - 16,
                                     120,
                                     kMinimizedSize,
                                     kMinimizedSize);
    self = [super initWithFrame:initialFrame];
    if (self) {
        _currentState = FloatingViewStateMinimized;
        [self setupUI];
        [self setupGestures];
    }
    return self;
}

#pragma mark - UI Setup

- (void)setupUI {
    self.backgroundColor = [UIColor clearColor];
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOffset = CGSizeMake(0, 6);
    self.layer.shadowRadius = 12.0;
    self.layer.shadowOpacity = 0.5;
    
    [self setupMinimizedView];
    [self setupExpandedView];
    
    // Initial state is minimized
    self.minimizedContainer.alpha = 1.0;
    self.expandedContainer.alpha = 0.0;
    self.expandedContainer.hidden = YES;
}

- (void)setupMinimizedView {
    self.minimizedContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kMinimizedSize, kMinimizedSize)];
    self.minimizedContainer.backgroundColor = [UIColor colorWithRed:0.08 green:0.11 blue:0.17 alpha:0.95];
    self.minimizedContainer.layer.cornerRadius = kMinimizedSize / 2.0;
    self.minimizedContainer.layer.borderColor = [UIColor colorWithRed:0.35 green:0.45 blue:0.95 alpha:0.8].CGColor;
    self.minimizedContainer.layer.borderWidth = 1.5;
    self.minimizedContainer.clipsToBounds = YES;
    [self addSubview:self.minimizedContainer];
    
    self.minimizedBadgeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, kMinimizedSize, kMinimizedSize)];
    self.minimizedBadgeLabel.text = @"DA";
    self.minimizedBadgeLabel.textColor = [UIColor colorWithRed:0.45 green:0.75 blue:1.0 alpha:1.0];
    self.minimizedBadgeLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightHeavy];
    self.minimizedBadgeLabel.textAlignment = NSTextAlignmentCenter;
    [self.minimizedContainer addSubview:self.minimizedBadgeLabel];
    
    // Status Dot (Green pulse)
    self.minimizedStatusDot = [[UIView alloc] initWithFrame:CGRectMake(kMinimizedSize - 14, 6, 8, 8)];
    self.minimizedStatusDot.backgroundColor = [UIColor colorWithRed:0.15 green:0.85 blue:0.40 alpha:1.0];
    self.minimizedStatusDot.layer.cornerRadius = 4.0;
    self.minimizedStatusDot.layer.borderColor = [UIColor colorWithRed:0.08 green:0.11 blue:0.17 alpha:1.0].CGColor;
    self.minimizedStatusDot.layer.borderWidth = 1.0;
    [self.minimizedContainer addSubview:self.minimizedStatusDot];
}

- (void)setupExpandedView {
    self.expandedContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kExpandedWidth, kExpandedHeight)];
    self.expandedContainer.backgroundColor = [UIColor colorWithRed:0.09 green:0.12 blue:0.18 alpha:0.98];
    self.expandedContainer.layer.cornerRadius = 16.0;
    self.expandedContainer.layer.borderColor = [UIColor colorWithRed:0.25 green:0.32 blue:0.45 alpha:0.8].CGColor;
    self.expandedContainer.layer.borderWidth = 1.0;
    self.expandedContainer.clipsToBounds = YES;
    [self addSubview:self.expandedContainer];
    
    // Header Bar
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kExpandedWidth, 42)];
    header.backgroundColor = [UIColor colorWithRed:0.12 green:0.16 blue:0.24 alpha:0.9];
    [self.expandedContainer addSubview:header];
    
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(14, 0, 150, 42)];
    self.titleLabel.text = @"Define Aura";
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
    [header addSubview:self.titleLabel];
    
    // Minimize Button ("-")
    self.minimizeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.minimizeButton.frame = CGRectMake(kExpandedWidth - 36, 6, 30, 30);
    [self.minimizeButton setTitle:@"✕" forState:UIControlStateNormal];
    [self.minimizeButton setTitleColor:[UIColor colorWithWhite:0.75 alpha:1.0] forState:UIControlStateNormal];
    self.minimizeButton.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightBold];
    [self.minimizeButton addTarget:self action:@selector(minimizeTapped) forControlEvents:UIControlEventTouchUpInside];
    [header addSubview:self.minimizeButton];
    
    // Status text
    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(14, 52, kExpandedWidth - 28, 20)];
    self.statusLabel.text = @"● Status: Active & Authorized";
    self.statusLabel.textColor = [UIColor colorWithRed:0.25 green:0.85 blue:0.50 alpha:1.0];
    self.statusLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    [self.expandedContainer addSubview:self.statusLabel];
    
    // Expiry info
    self.expiryLabel = [[UILabel alloc] initWithFrame:CGRectMake(14, 76, kExpandedWidth - 28, 20)];
    self.expiryLabel.text = @"Expires: Unlimited";
    self.expiryLabel.textColor = [UIColor colorWithRed:0.65 green:0.70 blue:0.80 alpha:1.0];
    self.expiryLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightRegular];
    [self.expandedContainer addSubview:self.expiryLabel];
    
    // Divider
    UIView *divider = [[UIView alloc] initWithFrame:CGRectMake(14, 106, kExpandedWidth - 28, 1)];
    divider.backgroundColor = [UIColor colorWithRed:0.20 green:0.25 blue:0.35 alpha:0.6];
    [self.expandedContainer addSubview:divider];
    
    // Module Toggle Row
    UILabel *toggleLabel = [[UILabel alloc] initWithFrame:CGRectMake(14, 120, 130, 30)];
    toggleLabel.text = @"Module Core";
    toggleLabel.textColor = [UIColor whiteColor];
    toggleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    [self.expandedContainer addSubview:toggleLabel];
    
    self.moduleSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(kExpandedWidth - 65, 120, 51, 31)];
    self.moduleSwitch.on = YES;
    self.moduleSwitch.onTintColor = [UIColor colorWithRed:0.25 green:0.45 blue:0.95 alpha:1.0];
    [self.moduleSwitch addTarget:self action:@selector(moduleSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    [self.expandedContainer addSubview:self.moduleSwitch];
    
    // Action Button
    UIButton *actionBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    actionBtn.frame = CGRectMake(14, 164, kExpandedWidth - 28, 36);
    actionBtn.backgroundColor = [UIColor colorWithRed:0.18 green:0.24 blue:0.36 alpha:0.8];
    actionBtn.layer.cornerRadius = 8.0;
    [actionBtn setTitle:@"Execute Action" forState:UIControlStateNormal];
    [actionBtn setTitleColor:[UIColor colorWithRed:0.45 green:0.75 blue:1.0 alpha:1.0] forState:UIControlStateNormal];
    actionBtn.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
    [actionBtn addTarget:self action:@selector(actionButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.expandedContainer addSubview:actionBtn];
    
    // Logout / Relogin Button
    self.logoutButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.logoutButton.frame = CGRectMake(14, 210, kExpandedWidth - 28, 32);
    self.logoutButton.backgroundColor = [UIColor colorWithRed:0.65 green:0.18 blue:0.18 alpha:0.15];
    self.logoutButton.layer.cornerRadius = 8.0;
    self.logoutButton.layer.borderColor = [UIColor colorWithRed:0.75 green:0.25 blue:0.25 alpha:0.4].CGColor;
    self.logoutButton.layer.borderWidth = 1.0;
    [self.logoutButton setTitle:@"Logout Session" forState:UIControlStateNormal];
    [self.logoutButton setTitleColor:[UIColor colorWithRed:1.0 green:0.45 blue:0.45 alpha:1.0] forState:UIControlStateNormal];
    self.logoutButton.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    [self.logoutButton addTarget:self action:@selector(logoutButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.expandedContainer addSubview:self.logoutButton];
}

#pragma mark - Gestures & Dragging

- (void)setupGestures {
    // Pan gesture for dragging
    self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self addGestureRecognizer:self.panGesture];
    
    // Tap gesture to toggle expansion when minimized
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tap.cancelsTouchesInView = NO;
    [self addGestureRecognizer:tap];
}

- (void)handleTap:(UITapGestureRecognizer *)gesture {
    if (self.currentState == FloatingViewStateMinimized) {
        CGPoint tapPoint = [gesture locationInView:self];
        if (CGRectContainsPoint(self.minimizedContainer.bounds, tapPoint)) {
            [self setExpanded:YES animated:YES];
        }
    }
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:self.superview];
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        self.touchOffset = CGPointMake(self.center.x, self.center.y);
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        CGPoint newCenter = CGPointMake(self.touchOffset.x + translation.x,
                                        self.touchOffset.y + translation.y);
        self.center = newCenter;
    } else if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled) {
        [self clampToScreenBoundsAnimated];
    }
}

- (void)clampToScreenBoundsAnimated {
    CGRect screen = [UIScreen mainScreen].bounds;
    CGFloat padding = 12.0;
    CGFloat topPadding = 44.0;
    
    CGRect currentFrame = self.frame;
    
    CGFloat minX = padding;
    CGFloat maxX = screen.size.width - currentFrame.size.width - padding;
    CGFloat minY = topPadding;
    CGFloat maxY = screen.size.height - currentFrame.size.height - padding;
    
    CGFloat targetX = currentFrame.origin.x;
    CGFloat targetY = currentFrame.origin.y;
    
    // Clamp Y
    if (targetY < minY) targetY = minY;
    if (targetY > maxY) targetY = maxY;
    
    // Clamp X, or snap to nearest edge if minimized
    if (self.currentState == FloatingViewStateMinimized) {
        CGFloat midX = screen.size.width / 2.0;
        if (self.center.x < midX) {
            targetX = minX;
        } else {
            targetX = maxX;
        }
    } else {
        if (targetX < minX) targetX = minX;
        if (targetX > maxX) targetX = maxX;
    }
    
    CGRect targetFrame = CGRectMake(targetX, targetY, currentFrame.size.width, currentFrame.size.height);
    
    [UIView animateWithDuration:0.3
                          delay:0.0
         usingSpringWithDamping:0.8
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        self.frame = targetFrame;
    } completion:nil];
}

#pragma mark - State Toggle

- (void)setExpanded:(BOOL)expanded animated:(BOOL)animated {
    if (expanded && self.currentState == FloatingViewStateExpanded) return;
    if (!expanded && self.currentState == FloatingViewStateMinimized) return;
    
    self.currentState = expanded ? FloatingViewStateExpanded : FloatingViewStateMinimized;
    
    CGRect screen = [UIScreen mainScreen].bounds;
    CGPoint currentCenter = self.center;
    
    CGFloat newWidth = expanded ? kExpandedWidth : kMinimizedSize;
    CGFloat newHeight = expanded ? kExpandedHeight : kMinimizedSize;
    
    // Adjust frame origin so it doesn't expand off-screen
    CGFloat newX = currentCenter.x - (newWidth / 2.0);
    CGFloat newY = currentCenter.y - (newHeight / 2.0);
    
    if (newX < 12.0) newX = 12.0;
    if (newX + newWidth > screen.size.width - 12.0) newX = screen.size.width - newWidth - 12.0;
    if (newY < 44.0) newY = 44.0;
    if (newY + newHeight > screen.size.height - 12.0) newY = screen.size.height - newHeight - 12.0;
    
    CGRect newFrame = CGRectMake(newX, newY, newWidth, newHeight);
    
    if (expanded) {
        self.expandedContainer.hidden = NO;
    } else {
        self.minimizedContainer.hidden = NO;
    }
    
    void (^animations)(void) = ^{
        self.frame = newFrame;
        if (expanded) {
            self.minimizedContainer.alpha = 0.0;
            self.expandedContainer.alpha = 1.0;
        } else {
            self.minimizedContainer.alpha = 1.0;
            self.expandedContainer.alpha = 0.0;
        }
    };
    
    void (^completion)(BOOL) = ^(BOOL finished) {
        if (expanded) {
            self.minimizedContainer.hidden = YES;
        } else {
            self.expandedContainer.hidden = YES;
            [self clampToScreenBoundsAnimated];
        }
        
        if ([self.delegate respondsToSelector:@selector(floatingViewDidChangeState:)]) {
            [self.delegate floatingViewDidChangeState:self.currentState];
        }
    };
    
    if (animated) {
        [UIView animateWithDuration:0.32
                              delay:0.0
             usingSpringWithDamping:0.82
              initialSpringVelocity:0.4
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:animations
                         completion:completion];
    } else {
        animations();
        completion(YES);
    }
}

- (void)minimizeTapped {
    [self setExpanded:NO animated:YES];
}

#pragma mark - Public Methods

- (void)updateStatus:(NSString *)statusText expiry:(nullable NSString *)expiryText {
    if (statusText) {
        self.statusLabel.text = [NSString stringWithFormat:@"● Status: %@", statusText];
    }
    if (expiryText) {
        self.expiryLabel.text = [NSString stringWithFormat:@"Expires: %@", expiryText];
    }
}

#pragma mark - Actions

- (void)moduleSwitchChanged:(UISwitch *)sender {
    if (sender.isOn) {
        self.statusLabel.text = @"● Status: Active & Authorized";
        self.statusLabel.textColor = [UIColor colorWithRed:0.25 green:0.85 blue:0.50 alpha:1.0];
        self.minimizedStatusDot.backgroundColor = [UIColor colorWithRed:0.15 green:0.85 blue:0.40 alpha:1.0];
    } else {
        self.statusLabel.text = @"● Status: Paused";
        self.statusLabel.textColor = [UIColor colorWithRed:0.85 green:0.65 blue:0.20 alpha:1.0];
        self.minimizedStatusDot.backgroundColor = [UIColor colorWithRed:0.85 green:0.65 blue:0.20 alpha:1.0];
    }
    
    [[ModuleInterface sharedModule] executeFeatureActionNamed:@"toggleCoreState"
                                                   parameters:@{@"active": @(sender.isOn)}];
}

- (void)actionButtonTapped {
    [[ModuleInterface sharedModule] executeFeatureActionNamed:@"triggerQuickAction"
                                                   parameters:@{@"timestamp": @([[NSDate date] timeIntervalSince1970])}];
}

- (void)logoutButtonTapped {
    if ([self.delegate respondsToSelector:@selector(floatingViewDidRequestLogout:)]) {
        [self.delegate floatingViewDidRequestLogout:self];
    }
}

@end
