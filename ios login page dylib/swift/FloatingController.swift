//
//  FloatingController.swift
//  DefineAura
//
//  Manages the dedicated floating UI overlay window and touch pass-through.
//

import UIKit

fileprivate class FloatingOverlayWindow: UIWindow {
    weak var targetFloatingView: FloatingView?
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        if let floating = targetFloatingView, !floating.isHidden {
            let localPoint = convert(point, to: floating)
            if floating.point(inside: localPoint, with: event) {
                return hitView
            }
        }
        return nil
    }
}

fileprivate class FloatingContainerViewController: UIViewController {
    override var shouldAutorotate: Bool { return true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { return .all }
}

public class FloatingController: FloatingViewDelegate {
    public static let shared = FloatingController()
    
    private var overlayWindow: FloatingOverlayWindow?
    public private(set) var floatingView: FloatingView?
    public private(set) var isVisible: Bool = false
    
    private init() {}
    
    public func showFloatingUI(expiry: String? = nil) {
        if isVisible, let floating = floatingView {
            floating.updateStatus(status: "Active & Authorized", expiry: expiry)
            return
        }
        
        DispatchQueue.main.async {
            let bounds = UIScreen.main.bounds
            
            var activeScene: UIWindowScene? = nil
            if #available(iOS 13.0, *) {
                activeScene = UIApplication.shared.connectedScenes
                    .filter { $0.activationState == .foregroundActive }
                    .first as? UIWindowScene
            }
            
            let window: FloatingOverlayWindow
            if #available(iOS 13.0, *), let scene = activeScene {
                window = FloatingOverlayWindow(windowScene: scene)
            } else {
                window = FloatingOverlayWindow(frame: bounds)
            }
            
            window.backgroundColor = .clear
            window.windowLevel = .alert + 10.0
            window.clipsToBounds = false
            
            let rootVC = FloatingContainerViewController()
            rootVC.view.backgroundColor = .clear
            window.rootViewController = rootVC
            
            let floating = FloatingView(frame: .zero)
            floating.delegate = self
            floating.updateStatus(status: "Active & Authorized", expiry: expiry)
            
            rootVC.view.addSubview(floating)
            window.targetFloatingView = floating
            
            self.overlayWindow = window
            self.floatingView = floating
            
            window.isHidden = false
            window.makeKeyAndVisible()
            
            floating.alpha = 0.0
            floating.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0.6, options: .curveEaseOut) {
                floating.alpha = 1.0
                floating.transform = .identity
            }
            
            self.isVisible = true
        }
    }
    
    public func hideFloatingUI() {
        guard isVisible else { return }
        
        DispatchQueue.main.async {
            guard let floating = self.floatingView else { return }
            UIView.animate(withDuration: 0.25) {
                floating.alpha = 0.0
                floating.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            } completion: { _ in
                floating.removeFromSuperview()
                self.floatingView = nil
                self.overlayWindow?.isHidden = true
                self.overlayWindow = nil
                self.isVisible = false
            }
        }
    }
    
    // MARK: - FloatingViewDelegate
    
    public func floatingViewDidChangeState(_ newState: FloatingViewState) {
        print("[DefineAura] Floating view changed state to \(newState)")
    }
    
    public func floatingViewDidRequestLogout(_ view: FloatingView) {
        hideFloatingUI()
        LoginManager.shared.logout()
        NotificationCenter.default.post(name: NSNotification.Name("DefineAuraDidRequestLoginNotification"), object: nil)
    }
}
