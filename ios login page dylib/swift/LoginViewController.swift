//
//  LoginViewController.swift
//  DefineAura
//
//  Professional dark login interface with custom styling, validation alerts,
//  and animated dismissal.
//

import UIKit

public class LoginViewController: UIViewController, UITextFieldDelegate, LoginManagerDelegate {
    
    public var onLoginSuccess: (() -> Void)?
    
    private let cardView = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let keyTextField = UITextField()
    private let loginButton = UIButton(type: .custom)
    private let pasteButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let statusBannerLabel = UILabel()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        LoginManager.shared.delegate = self
        setupDarkThemeUI()
        populateSavedKey()
        setupKeyboardDismissal()
    }
    
    private func setupDarkThemeUI() {
        view.backgroundColor = UIColor(red: 0.04, green: 0.06, blue: 0.10, alpha: 0.95)
        
        let bgGradient = CAGradientLayer()
        bgGradient.frame = UIScreen.main.bounds
        bgGradient.colors = [
            UIColor(red: 0.07, green: 0.09, blue: 0.16, alpha: 1.0).cgColor,
            UIColor(red: 0.04, green: 0.05, blue: 0.09, alpha: 1.0).cgColor
        ]
        view.layer.insertSublayer(bgGradient, at: 0)
        
        // Card View
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.backgroundColor = UIColor(red: 0.09, green: 0.12, blue: 0.18, alpha: 0.96)
        cardView.layer.cornerRadius = 20.0
        cardView.layer.borderColor = UIColor(red: 0.20, green: 0.25, blue: 0.35, alpha: 0.7).cgColor
        cardView.layer.borderWidth = 1.0
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOffset = CGSize(width: 0, height: 10)
        cardView.layer.shadowRadius = 25.0
        cardView.layer.shadowOpacity = 0.55
        view.addSubview(cardView)
        
        // Badge
        let badgeView = UIView()
        badgeView.translatesAutoresizingMaskIntoConstraints = false
        badgeView.backgroundColor = UIColor(red: 0.25, green: 0.35, blue: 0.95, alpha: 0.18)
        badgeView.layer.cornerRadius = 24.0
        badgeView.layer.borderColor = UIColor(red: 0.38, green: 0.50, blue: 1.0, alpha: 0.45).cgColor
        badgeView.layer.borderWidth = 1.5
        cardView.addSubview(badgeView)
        
        let badgeLabel = UILabel()
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        badgeLabel.text = "DA"
        badgeLabel.textColor = UIColor(red: 0.45, green: 0.72, blue: 1.0, alpha: 1.0)
        badgeLabel.font = .systemFont(ofSize: 18, weight: .heavy)
        badgeLabel.textAlignment = .center
        badgeView.addSubview(badgeLabel)
        
        // Title
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Define Aura"
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .center
        cardView.addSubview(titleLabel)
        
        // Subtitle
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "Enter your license key to activate session"
        subtitleLabel.textColor = UIColor(red: 0.60, green: 0.66, blue: 0.76, alpha: 1.0)
        subtitleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textAlignment = .center
        cardView.addSubview(subtitleLabel)
        
        // Status Banner
        statusBannerLabel.translatesAutoresizingMaskIntoConstraints = false
        statusBannerLabel.font = .systemFont(ofSize: 12, weight: .medium)
        statusBannerLabel.textAlignment = .center
        statusBannerLabel.numberOfLines = 0
        statusBannerLabel.layer.cornerRadius = 8.0
        statusBannerLabel.clipsToBounds = true
        statusBannerLabel.alpha = 0.0
        cardView.addSubview(statusBannerLabel)
        
        // Field Container
        let fieldContainer = UIView()
        fieldContainer.translatesAutoresizingMaskIntoConstraints = false
        fieldContainer.backgroundColor = UIColor(red: 0.06, green: 0.08, blue: 0.12, alpha: 0.9)
        fieldContainer.layer.cornerRadius = 12.0
        fieldContainer.layer.borderWidth = 1.0
        fieldContainer.layer.borderColor = UIColor(red: 0.22, green: 0.27, blue: 0.38, alpha: 0.6).cgColor
        cardView.addSubview(fieldContainer)
        
        // Key Field
        keyTextField.translatesAutoresizingMaskIntoConstraints = false
        keyTextField.attributedPlaceholder = NSAttributedString(
            string: "Enter License Key...",
            attributes: [.foregroundColor: UIColor(white: 0.45, alpha: 1.0)]
        )
        keyTextField.textColor = .white
        keyTextField.font = UIFont(name: "Courier-Bold", size: 14) ?? .systemFont(ofSize: 14, weight: .medium)
        keyTextField.autocapitalizationType = .none
        keyTextField.autocorrectionType = .no
        keyTextField.returnKeyType = .done
        keyTextField.clearButtonMode = .whileEditing
        keyTextField.delegate = self
        fieldContainer.addSubview(keyTextField)
        
        // Paste Button
        pasteButton.translatesAutoresizingMaskIntoConstraints = false
        pasteButton.setTitle("Paste", for: .normal)
        pasteButton.setTitleColor(UIColor(red: 0.38, green: 0.65, blue: 1.0, alpha: 1.0), for: .normal)
        pasteButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
        pasteButton.addTarget(self, action: #selector(pasteClipboardKey), for: .touchUpInside)
        fieldContainer.addSubview(pasteButton)
        
        // Login Button
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        loginButton.backgroundColor = UIColor(red: 0.25, green: 0.40, blue: 0.95, alpha: 1.0)
        loginButton.layer.cornerRadius = 12.0
        loginButton.setTitle("Login", for: .normal)
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        loginButton.layer.shadowColor = UIColor(red: 0.25, green: 0.40, blue: 0.95, alpha: 0.5).cgColor
        loginButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        loginButton.layer.shadowRadius = 8.0
        loginButton.layer.shadowOpacity = 0.6
        loginButton.addTarget(self, action: #selector(loginButtonPressed), for: .touchUpInside)
        cardView.addSubview(loginButton)
        
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.color = .white
        activityIndicator.hidesWhenStopped = true
        loginButton.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            cardView.centerXAnchor constraintEqualToAnchor view.centerXAnchor,
            cardView.centerYAnchor constraintEqualToAnchor view.centerYAnchor,
            cardView.widthAnchor constraintEqualToConstant 320,
            
            badgeView.centerXAnchor constraintEqualToAnchor cardView.centerXAnchor,
            badgeView.topAnchor constraintEqualToAnchor cardView.topAnchor constant 24,
            badgeView.widthAnchor constraintEqualToConstant 48,
            badgeView.heightAnchor constraintEqualToConstant 48,
            
            badgeLabel.centerXAnchor constraintEqualToAnchor badgeView.centerXAnchor,
            badgeLabel.centerYAnchor constraintEqualToAnchor badgeView.centerYAnchor,
            
            titleLabel.topAnchor constraintEqualToAnchor badgeView.bottomAnchor constant 12,
            titleLabel.leadingAnchor constraintEqualToAnchor cardView.leadingAnchor constant 16,
            titleLabel.trailingAnchor constraintEqualToAnchor cardView.trailingAnchor constant -16,
            
            subtitleLabel.topAnchor constraintEqualToAnchor titleLabel.bottomAnchor constant 4,
            subtitleLabel.leadingAnchor constraintEqualToAnchor cardView.leadingAnchor constant 16,
            subtitleLabel.trailingAnchor constraintEqualToAnchor cardView.trailingAnchor constant -16,
            
            statusBannerLabel.topAnchor constraintEqualToAnchor subtitleLabel.bottomAnchor constant 12,
            statusBannerLabel.leadingAnchor constraintEqualToAnchor cardView.leadingAnchor constant 20,
            statusBannerLabel.trailingAnchor constraintEqualToAnchor cardView.trailingAnchor constant -20,
            
            fieldContainer.topAnchor constraintEqualToAnchor statusBannerLabel.bottomAnchor constant 8,
            fieldContainer.leadingAnchor constraintEqualToAnchor cardView.leadingAnchor constant 20,
            fieldContainer.trailingAnchor constraintEqualToAnchor cardView.trailingAnchor constant -20,
            fieldContainer.heightAnchor constraintEqualToConstant 46,
            
            keyTextField.leadingAnchor constraintEqualToAnchor fieldContainer.leadingAnchor constant 12,
            keyTextField.centerYAnchor constraintEqualToAnchor fieldContainer.centerYAnchor,
            keyTextField.trailingAnchor constraintEqualToAnchor pasteButton.leadingAnchor constant -8,
            
            pasteButton.trailingAnchor constraintEqualToAnchor fieldContainer.trailingAnchor constant -12,
            pasteButton.centerYAnchor constraintEqualToAnchor fieldContainer.centerYAnchor,
            pasteButton.widthAnchor constraintEqualToConstant 44,
            
            loginButton.topAnchor constraintEqualToAnchor fieldContainer.bottomAnchor constant 16,
            loginButton.leadingAnchor constraintEqualToAnchor cardView.leadingAnchor constant 20,
            loginButton.trailingAnchor constraintEqualToAnchor cardView.trailingAnchor constant -20,
            loginButton.heightAnchor constraintEqualToConstant 46,
            loginButton.bottomAnchor constraintEqualToAnchor cardView.bottomAnchor constant -24,
            
            activityIndicator.centerYAnchor constraintEqualToAnchor loginButton.centerYAnchor,
            activityIndicator.trailingAnchor constraintEqualToAnchor loginButton.trailingAnchor constant -16
        ])
    }
    
    private func populateSavedKey() {
        if let saved = SessionManager.shared.getStoredLicenseKey() {
            keyTextField.text = saved
        }
    }
    
    private func setupKeyboardDismissal() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func pasteClipboardKey() {
        if let str = UIPasteboard.general.string {
            keyTextField.text = str.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    @objc private func loginButtonPressed() {
        dismissKeyboard()
        guard let key = keyTextField.text, !key.isEmpty else {
            displayErrorBanner("Please enter your license key.", status: .invalidKey)
            return
        }
        LoginManager.shared.login(key: key)
    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        loginButtonPressed()
        return true
    }
    
    private func displayErrorBanner(_ message: String, status: AuthStatus) {
        statusBannerLabel.text = "  \(message)  "
        var bgColor = UIColor(red: 0.75, green: 0.18, blue: 0.18, alpha: 0.25)
        var textColor = UIColor(red: 1.0, green: 0.45, blue: 0.45, alpha: 1.0)
        
        switch status {
        case .invalidKey:
            bgColor = UIColor(red: 0.80, green: 0.20, blue: 0.20, alpha: 0.3)
            textColor = UIColor(red: 1.0, green: 0.40, blue: 0.40, alpha: 1.0)
        case .expiredKey:
            bgColor = UIColor(red: 0.85, green: 0.55, blue: 0.10, alpha: 0.3)
            textColor = UIColor(red: 1.0, green: 0.75, blue: 0.30, alpha: 1.0)
        case .networkError:
            bgColor = UIColor(red: 0.85, green: 0.40, blue: 0.05, alpha: 0.3)
            textColor = UIColor(red: 1.0, green: 0.60, blue: 0.30, alpha: 1.0)
        case .serverError:
            bgColor = UIColor(red: 0.70, green: 0.15, blue: 0.15, alpha: 0.3)
            textColor = UIColor(red: 1.0, green: 0.35, blue: 0.35, alpha: 1.0)
        case .success:
            bgColor = UIColor(red: 0.10, green: 0.75, blue: 0.40, alpha: 0.3)
            textColor = UIColor(red: 0.40, green: 1.0, blue: 0.60, alpha: 1.0)
        default:
            break
        }
        
        statusBannerLabel.backgroundColor = bgColor
        statusBannerLabel.textColor = textColor
        
        UIView.animate(withDuration: 0.25) {
            self.statusBannerLabel.alpha = 1.0
        }
    }
    
    // MARK: - LoginManagerDelegate
    
    public func loginDidBeginAuthenticating() {
        loginButton.isEnabled = false
        loginButton.alpha = 0.7
        loginButton.setTitle("Authenticating...", for: .normal)
        activityIndicator.startAnimating()
    }
    
    public func loginDidFail(status: AuthStatus, message: String) {
        loginButton.isEnabled = true
        loginButton.alpha = 1.0
        loginButton.setTitle("Login", for: .normal)
        activityIndicator.stopAnimating()
        displayErrorBanner(message, status: status)
    }
    
    public func loginDidSucceed(response: AuthResponse) {
        loginButton.isEnabled = false
        loginButton.setTitle("Authorized", for: .normal)
        loginButton.backgroundColor = UIColor(red: 0.10, green: 0.75, blue: 0.40, alpha: 1.0)
        activityIndicator.stopAnimating()
        displayErrorBanner("License Verified! Loading...", status: .success)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.dismissWithSuccessAnimation {
                self.onLoginSuccess?()
            }
        }
    }
    
    public func dismissWithSuccessAnimation(completion: (() -> Void)?) {
        UIView.animate(withDuration: 0.35, delay: 0.0, options: .curveEaseInOut) {
            self.cardView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
            self.view.alpha = 0.0
        } completion: { _ in
            self.view.removeFromSuperview()
            self.removeFromParent()
            completion?()
        }
    }
}
