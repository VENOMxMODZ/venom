//
//  LoginViewController.m
//  DefineAura
//
//  Professional dark login interface with custom styling, validation alerts,
//  and animated dismissal.
//

#import "LoginViewController.h"
#import "LoginManager.h"
#import "SessionManager.h"

@interface LoginViewController () <UITextFieldDelegate, LoginManagerDelegate>

@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UITextField *keyTextField;
@property (nonatomic, strong) UIButton *loginButton;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) UILabel *statusBannerLabel;
@property (nonatomic, strong) UIButton *pasteButton;

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [LoginManager sharedManager].delegate = self;
    
    [self setupDarkThemeUI];
    [self populateSavedKey];
    [self setupKeyboardDismissal];
}

#pragma mark - UI Setup

- (void)setupDarkThemeUI {
    self.view.backgroundColor = [UIColor colorWithRed:0.04 green:0.06 blue:0.10 alpha:0.95];
    
    // Add subtle ambient background glow
    CAGradientLayer *bgGradient = [CAGradientLayer layer];
    bgGradient.frame = [UIScreen mainScreen].bounds;
    bgGradient.colors = @[
        (id)[UIColor colorWithRed:0.07 green:0.09 blue:0.16 alpha:1.0].CGColor,
        (id)[UIColor colorWithRed:0.04 green:0.05 blue:0.09 alpha:1.0].CGColor
    ];
    bgGradient.startPoint = CGPointMake(0.5, 0.0);
    bgGradient.endPoint = CGPointMake(0.5, 1.0);
    [self.view.layer insertSublayer:bgGradient atIndex:0];
    
    // Main Card View
    self.cardView = [[UIView alloc] init];
    self.cardView.translatesAutoresizingMaskIntoConstraints = NO;
    self.cardView.backgroundColor = [UIColor colorWithRed:0.09 green:0.12 blue:0.18 alpha:0.96];
    self.cardView.layer.cornerRadius = 20.0;
    self.cardView.layer.borderColor = [UIColor colorWithRed:0.20 green:0.25 blue:0.35 alpha:0.7].CGColor;
    self.cardView.layer.borderWidth = 1.0;
    self.cardView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.cardView.layer.shadowOffset = CGSizeMake(0, 10);
    self.cardView.layer.shadowRadius = 25.0;
    self.cardView.layer.shadowOpacity = 0.55;
    [self.view addSubview:self.cardView];
    
    // Brand Badge / Logo Icon
    UIView *badgeView = [[UIView alloc] init];
    badgeView.translatesAutoresizingMaskIntoConstraints = NO;
    badgeView.backgroundColor = [UIColor colorWithRed:0.25 green:0.35 blue:0.95 alpha:0.18];
    badgeView.layer.cornerRadius = 24.0;
    badgeView.layer.borderColor = [UIColor colorWithRed:0.38 green:0.50 blue:1.0 alpha:0.45].CGColor;
    badgeView.layer.borderWidth = 1.5;
    [self.cardView addSubview:badgeView];
    
    UILabel *badgeLabel = [[UILabel alloc] init];
    badgeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    badgeLabel.text = @"DA";
    badgeLabel.textColor = [UIColor colorWithRed:0.45 green:0.72 blue:1.0 alpha:1.0];
    badgeLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightHeavy];
    badgeLabel.textAlignment = NSTextAlignmentCenter;
    [badgeView addSubview:badgeLabel];
    
    // Application Title
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.text = @"Define Aura";
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.font = [UIFont systemFontOfSize:24 weight:UIFontWeightBold];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.cardView addSubview:self.titleLabel];
    
    // Subtitle
    self.subtitleLabel = [[UILabel alloc] init];
    self.subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.subtitleLabel.text = @"Enter your license key to activate session";
    self.subtitleLabel.textColor = [UIColor colorWithRed:0.60 green:0.66 blue:0.76 alpha:1.0];
    self.subtitleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
    self.subtitleLabel.textAlignment = NSTextAlignmentCenter;
    [self.cardView addSubview:self.subtitleLabel];
    
    // Status / Error Banner
    self.statusBannerLabel = [[UILabel alloc] init];
    self.statusBannerLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.statusBannerLabel.text = @"";
    self.statusBannerLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    self.statusBannerLabel.textAlignment = NSTextAlignmentCenter;
    self.statusBannerLabel.numberOfLines = 0;
    self.statusBannerLabel.layer.cornerRadius = 8.0;
    self.statusBannerLabel.clipsToBounds = YES;
    self.statusBannerLabel.alpha = 0.0;
    [self.cardView addSubview:self.statusBannerLabel];
    
    // Key Text Field Container
    UIView *fieldContainer = [[UIView alloc] init];
    fieldContainer.translatesAutoresizingMaskIntoConstraints = NO;
    fieldContainer.backgroundColor = [UIColor colorWithRed:0.06 green:0.08 blue:0.12 alpha:0.9];
    fieldContainer.layer.cornerRadius = 12.0;
    fieldContainer.layer.borderWidth = 1.0;
    fieldContainer.layer.borderColor = [UIColor colorWithRed:0.22 green:0.27 blue:0.38 alpha:0.6].CGColor;
    [self.cardView addSubview:fieldContainer];
    
    // Text Field
    self.keyTextField = [[UITextField alloc] init];
    self.keyTextField.translatesAutoresizingMaskIntoConstraints = NO;
    self.keyTextField.placeholder = @"Enter License Key...";
    self.keyTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Enter License Key..."
                                                                             attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:0.45 alpha:1.0]}];
    self.keyTextField.textColor = [UIColor whiteColor];
    self.keyTextField.font = [UIFont fontWithName:@"Courier-Bold" size:14] ?: [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    self.keyTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.keyTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.keyTextField.returnKeyType = UIReturnKeyDone;
    self.keyTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.keyTextField.delegate = self;
    [fieldContainer addSubview:self.keyTextField];
    
    // Quick Paste Button inside text container
    self.pasteButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.pasteButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.pasteButton setTitle:@"Paste" forState:UIControlStateNormal];
    [self.pasteButton setTitleColor:[UIColor colorWithRed:0.38 green:0.65 blue:1.0 alpha:1.0] forState:UIControlStateNormal];
    self.pasteButton.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
    [self.pasteButton addTarget:self action:@selector(pasteClipboardKey) forControlEvents:UIControlEventTouchUpInside];
    [fieldContainer addSubview:self.pasteButton];
    
    // Login Button
    self.loginButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.loginButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.loginButton.backgroundColor = [UIColor colorWithRed:0.25 green:0.40 blue:0.95 alpha:1.0];
    self.loginButton.layer.cornerRadius = 12.0;
    [self.loginButton setTitle:@"Login" forState:UIControlStateNormal];
    [self.loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.loginButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
    self.loginButton.layer.shadowColor = [UIColor colorWithRed:0.25 green:0.40 blue:0.95 alpha:0.5].CGColor;
    self.loginButton.layer.shadowOffset = CGSizeMake(0, 4);
    self.loginButton.layer.shadowRadius = 8.0;
    self.loginButton.layer.shadowOpacity = 0.6;
    [self.loginButton addTarget:self action:@selector(loginButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.cardView addSubview:self.loginButton];
    
    // Activity Indicator inside button
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    self.activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    self.activityIndicator.color = [UIColor whiteColor];
    self.activityIndicator.hidesWhenStopped = YES;
    [self.loginButton addSubview:self.activityIndicator];
    
    // Auto Layout Constraints
    [NSLayoutConstraint activateConstraints:@[
        // Card constraints (centered, responsive width)
        [self.cardView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.cardView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [self.cardView.widthAnchor constraintEqualToConstant:320],
        
        // Badge
        [badgeView.centerXAnchor constraintEqualToAnchor:self.cardView.centerXAnchor],
        [badgeView.topAnchor constraintEqualToAnchor:self.cardView.topAnchor constant:24],
        [badgeView.widthAnchor constraintEqualToConstant:48],
        [badgeView.heightAnchor constraintEqualToConstant:48],
        
        [badgeLabel.centerXAnchor constraintEqualToAnchor:badgeView.centerXAnchor],
        [badgeLabel.centerYAnchor constraintEqualToAnchor:badgeView.centerYAnchor],
        
        // Title
        [self.titleLabel.topAnchor constraintEqualToAnchor:badgeView.bottomAnchor constant:12],
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor constant:16],
        [self.titleLabel.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor constant:-16],
        
        // Subtitle
        [self.subtitleLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:4],
        [self.subtitleLabel.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor constant:16],
        [self.subtitleLabel.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor constant:-16],
        
        // Status Banner
        [self.statusBannerLabel.topAnchor constraintEqualToAnchor:self.subtitleLabel.bottomAnchor constant:12],
        [self.statusBannerLabel.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor constant:20],
        [self.statusBannerLabel.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor constant:-20],
        
        // Field Container
        [fieldContainer.topAnchor constraintEqualToAnchor:self.statusBannerLabel.bottomAnchor constant:8],
        [fieldContainer.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor constant:20],
        [fieldContainer.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor constant:-20],
        [fieldContainer.heightAnchor constraintEqualToConstant:46],
        
        // Key Text Field
        [self.keyTextField.leadingAnchor constraintEqualToAnchor:fieldContainer.leadingAnchor constant:12],
        [self.keyTextField.centerYAnchor constraintEqualToAnchor:fieldContainer.centerYAnchor],
        [self.keyTextField.trailingAnchor constraintEqualToAnchor:self.pasteButton.leadingAnchor constant:-8],
        
        // Paste Button
        [self.pasteButton.trailingAnchor constraintEqualToAnchor:fieldContainer.trailingAnchor constant:-12],
        [self.pasteButton.centerYAnchor constraintEqualToAnchor:fieldContainer.centerYAnchor],
        [self.pasteButton.widthAnchor constraintEqualToConstant:44],
        
        // Login Button
        [self.loginButton.topAnchor constraintEqualToAnchor:fieldContainer.bottomAnchor constant:16],
        [self.loginButton.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor constant:20],
        [self.loginButton.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor constant:-20],
        [self.loginButton.heightAnchor constraintEqualToConstant:46],
        [self.loginButton.bottomAnchor constraintEqualToAnchor:self.cardView.bottomAnchor constant:-24],
        
        // Indicator
        [self.activityIndicator.centerYAnchor constraintEqualToAnchor:self.loginButton.centerYAnchor],
        [self.activityIndicator.trailingAnchor constraintEqualToAnchor:self.loginButton.trailingAnchor constant:-16]
    ]];
}

- (void)populateSavedKey {
    NSString *saved = [[SessionManager sharedManager] getStoredLicenseKey];
    if (saved && saved.length > 0) {
        self.keyTextField.text = saved;
    }
}

- (void)setupKeyboardDismissal {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

- (void)pasteClipboardKey {
    UIPasteboard *pb = [UIPasteboard generalPasteboard];
    if (pb.string && pb.string.length > 0) {
        self.keyTextField.text = [pb.string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
}

#pragma mark - Actions

- (void)loginButtonPressed {
    [self dismissKeyboard];
    
    NSString *key = self.keyTextField.text;
    if (!key || key.length == 0) {
        [self displayErrorBanner:@"Please enter your license key." colorType:AuthStatusInvalidKey];
        return;
    }
    
    [[LoginManager sharedManager] loginWithKey:key];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    [self loginButtonPressed];
    return YES;
}

#pragma mark - Feedback & Alerts

- (void)displayErrorBanner:(NSString *)message colorType:(AuthStatus)status {
    self.statusBannerLabel.text = [NSString stringWithFormat:@"  %@  ", message];
    
    UIColor *bgColor = [UIColor colorWithRed:0.75 green:0.18 blue:0.18 alpha:0.25];
    UIColor *textColor = [UIColor colorWithRed:1.0 green:0.45 blue:0.45 alpha:1.0];
    
    switch (status) {
        case AuthStatusInvalidKey:
            bgColor = [UIColor colorWithRed:0.80 green:0.20 blue:0.20 alpha:0.3];
            textColor = [UIColor colorWithRed:1.0 green:0.40 blue:0.40 alpha:1.0];
            break;
        case AuthStatusExpiredKey:
            bgColor = [UIColor colorWithRed:0.85 green:0.55 blue:0.10 alpha:0.3];
            textColor = [UIColor colorWithRed:1.0 green:0.75 blue:0.30 alpha:1.0];
            break;
        case AuthStatusNetworkError:
            bgColor = [UIColor colorWithRed:0.85 green:0.40 blue:0.05 alpha:0.3];
            textColor = [UIColor colorWithRed:1.0 green:0.60 blue:0.30 alpha:1.0];
            break;
        case AuthStatusServerError:
            bgColor = [UIColor colorWithRed:0.70 green:0.15 blue:0.15 alpha:0.3];
            textColor = [UIColor colorWithRed:1.0 green:0.35 blue:0.35 alpha:1.0];
            break;
        case AuthStatusSuccess:
            bgColor = [UIColor colorWithRed:0.10 green:0.75 blue:0.40 alpha:0.3];
            textColor = [UIColor colorWithRed:0.40 green:1.0 blue:0.60 alpha:1.0];
            break;
        default:
            break;
    }
    
    self.statusBannerLabel.backgroundColor = bgColor;
    self.statusBannerLabel.textColor = textColor;
    
    [UIView animateWithDuration:0.25 animations:^{
        self.statusBannerLabel.alpha = 1.0;
    }];
}

- (void)clearErrorBanner {
    [UIView animateWithDuration:0.2 animations:^{
        self.statusBannerLabel.alpha = 0.0;
    }];
}

#pragma mark - LoginManagerDelegate

- (void)loginDidBeginAuthenticating {
    [self clearErrorBanner];
    self.loginButton.enabled = NO;
    self.loginButton.alpha = 0.7;
    [self.loginButton setTitle:@"Authenticating..." forState:UIControlStateNormal];
    [self.activityIndicator startAnimating];
}

- (void)loginDidFailWithStatus:(AuthStatus)status message:(NSString *)errorMessage {
    self.loginButton.enabled = YES;
    self.loginButton.alpha = 1.0;
    [self.loginButton setTitle:@"Login" forState:UIControlStateNormal];
    [self.activityIndicator stopAnimating];
    
    [self displayErrorBanner:errorMessage colorType:status];
}

- (void)loginDidSucceedWithResponse:(AuthResponse *)response {
    self.loginButton.enabled = NO;
    [self.loginButton setTitle:@"Authorized" forState:UIControlStateNormal];
    self.loginButton.backgroundColor = [UIColor colorWithRed:0.10 green:0.75 blue:0.40 alpha:1.0];
    [self.activityIndicator stopAnimating];
    
    [self displayErrorBanner:@"License Verified! Loading..." colorType:AuthStatusSuccess];
    
    // Wait briefly for smooth visual feedback before dismissing
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self dismissWithSuccessAnimation:^{
            if (self.onLoginSuccess) {
                self.onLoginSuccess();
            }
        }];
    });
}

#pragma mark - Dismissal

- (void)dismissWithSuccessAnimation:(void (^ _Nullable)(void))completion {
    [UIView animateWithDuration:0.35
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
        self.cardView.transform = CGAffineTransformMakeScale(0.85, 0.85);
        self.view.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self.view removeFromSuperview];
        [self removeFromParentViewController];
        if (completion) {
            completion();
        }
    }];
}

@end
