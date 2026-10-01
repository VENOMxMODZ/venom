//
//  FloatingView.swift
//  DefineAura
//
//  Draggable, compact floating UI element capable of minimizing into a small
//  floating button and expanding into a sleek control panel.
//

import UIKit

public enum FloatingViewState {
    case minimized
    case expanded
}

public protocol FloatingViewDelegate: AnyObject {
    func floatingViewDidChangeState(_ newState: FloatingViewState)
    func floatingViewDidRequestLogout(_ view: FloatingView)
}

public class FloatingView: UIView {
    
    public weak var delegate: FloatingViewDelegate?
    public private(set) var currentState: FloatingViewState = .minimized
    
    private let minimizedSize: CGFloat = 52.0
    private let expandedWidth: CGFloat = 240.0
    private let expandedHeight: CGFloat = 260.0
    
    private var touchOffset: CGPoint = .zero
    
    // Minimized UI
    private let minimizedContainer = UIView()
    private let minimizedBadgeLabel = UILabel()
    private let minimizedStatusDot = UIView()
    
    // Expanded UI
    private let expandedContainer = UIView()
    private let titleLabel = UILabel()
    private let statusLabel = UILabel()
    private let expiryLabel = UILabel()
    private let moduleSwitch = UISwitch()
    private let minimizeButton = UIButton(type: .system)
    private let logoutButton = UIButton(type: .system)
    
    public override init(frame: CGRect) {
        let initialFrame = CGRect(
            x: UIScreen.main.bounds.width - 52 - 16,
            y: 120,
            width: 52,
            height: 52
        )
        super.init(frame: initialFrame)
        setupUI()
        setupGestures()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 6)
        layer.shadowRadius = 12.0
        layer.shadowOpacity = 0.5
        
        setupMinimized()
        setupExpanded()
        
        minimizedContainer.alpha = 1.0
        expandedContainer.alpha = 0.0
        expandedContainer.isHidden = true
    }
    
    private func setupMinimized() {
        minimizedContainer.frame = CGRect(x: 0, y: 0, width: minimizedSize, height: minimizedSize)
        minimizedContainer.backgroundColor = UIColor(red: 0.08, green: 0.11, blue: 0.17, alpha: 0.95)
        minimizedContainer.layer.cornerRadius = minimizedSize / 2.0
        minimizedContainer.layer.borderColor = UIColor(red: 0.35, green: 0.45, blue: 0.95, alpha: 0.8).cgColor
        minimizedContainer.layer.borderWidth = 1.5
        minimizedContainer.clipsToBounds = true
        addSubview(minimizedContainer)
        
        minimizedBadgeLabel.frame = minimizedContainer.bounds
        minimizedBadgeLabel.text = "DA"
        minimizedBadgeLabel.textColor = UIColor(red: 0.45, green: 0.75, blue: 1.0, alpha: 1.0)
        minimizedBadgeLabel.font = .systemFont(ofSize: 17, weight: .heavy)
        minimizedBadgeLabel.textAlignment = .center
        minimizedContainer.addSubview(minimizedBadgeLabel)
        
        minimizedStatusDot.frame = CGRect(x: minimizedSize - 14, y: 6, width: 8, height: 8)
        minimizedStatusDot.backgroundColor = UIColor(red: 0.15, green: 0.85, blue: 0.40, alpha: 1.0)
        minimizedStatusDot.layer.cornerRadius = 4.0
        minimizedStatusDot.layer.borderColor = UIColor(red: 0.08, green: 0.11, blue: 0.17, alpha: 1.0).cgColor
        minimizedStatusDot.layer.borderWidth = 1.0
        minimizedContainer.addSubview(minimizedStatusDot)
    }
    
    private func setupExpanded() {
        expandedContainer.frame = CGRect(x: 0, y: 0, width: expandedWidth, height: expandedHeight)
        expandedContainer.backgroundColor = UIColor(red: 0.09, green: 0.12, blue: 0.18, alpha: 0.98)
        expandedContainer.layer.cornerRadius = 16.0
        expandedContainer.layer.borderColor = UIColor(red: 0.25, green: 0.32, blue: 0.45, alpha: 0.8).cgColor
        expandedContainer.layer.borderWidth = 1.0
        expandedContainer.clipsToBounds = true
        addSubview(expandedContainer)
        
        let header = UIView(frame: CGRect(x: 0, y: 0, width: expandedWidth, height: 42))
        header.backgroundColor = UIColor(red: 0.12, green: 0.16, blue: 0.24, alpha: 0.9)
        expandedContainer.addSubview(header)
        
        titleLabel.frame = CGRect(x: 14, y: 0, width: 150, height: 42)
        titleLabel.text = "Define Aura"
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 14, weight: .bold)
        header.addSubview(titleLabel)
        
        minimizeButton.frame = CGRect(x: expandedWidth - 36, y: 6, width: 30, height: 30)
        minimizeButton.setTitle("✕", for: .normal)
        minimizeButton.setTitleColor(UIColor(white: 0.75, alpha: 1.0), for: .normal)
        minimizeButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .bold)
        minimizeButton.addTarget(self, action: #selector(minimizeTapped), for: .touchUpInside)
        header.addSubview(minimizeButton)
        
        statusLabel.frame = CGRect(x: 14, y: 52, width: expandedWidth - 28, height: 20)
        statusLabel.text = "● Status: Active & Authorized"
        statusLabel.textColor = UIColor(red: 0.25, green: 0.85, blue: 0.50, alpha: 1.0)
        statusLabel.font = .systemFont(ofSize: 12, weight: .medium)
        expandedContainer.addSubview(statusLabel)
        
        expiryLabel.frame = CGRect(x: 14, y: 76, width: expandedWidth - 28, height: 20)
        expiryLabel.text = "Expires: Unlimited"
        expiryLabel.textColor = UIColor(red: 0.65, green: 0.70, blue: 0.80, alpha: 1.0)
        expiryLabel.font = .systemFont(ofSize: 11, weight: .regular)
        expandedContainer.addSubview(expiryLabel)
        
        let divider = UIView(frame: CGRect(x: 14, y: 106, width: expandedWidth - 28, height: 1))
        divider.backgroundColor = UIColor(red: 0.20, green: 0.25, blue: 0.35, alpha: 0.6)
        expandedContainer.addSubview(divider)
        
        let toggleLabel = UILabel(frame: CGRect(x: 14, y: 120, width: 130, height: 30))
        toggleLabel.text = "Module Core"
        toggleLabel.textColor = .white
        toggleLabel.font = .systemFont(ofSize: 13, weight: .medium)
        expandedContainer.addSubview(toggleLabel)
        
        moduleSwitch.frame = CGRect(x: expandedWidth - 65, y: 120, width: 51, height: 31)
        moduleSwitch.isOn = true
        moduleSwitch.onTintColor = UIColor(red: 0.25, green: 0.45, blue: 0.95, alpha: 1.0)
        moduleSwitch.addTarget(self, action: #selector(moduleSwitchChanged(_:)), for: .valueChanged)
        expandedContainer.addSubview(moduleSwitch)
        
        let actionBtn = UIButton(type: .system)
        actionBtn.frame = CGRect(x: 14, y: 164, width: expandedWidth - 28, height: 36)
        actionBtn.backgroundColor = UIColor(red: 0.18, green: 0.24, blue: 0.36, alpha: 0.8)
        actionBtn.layer.cornerRadius = 8.0
        actionBtn.setTitle("Execute Action", for: .normal)
        actionBtn.setTitleColor(UIColor(red: 0.45, green: 0.75, blue: 1.0, alpha: 1.0), for: .normal)
        actionBtn.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
        actionBtn.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        expandedContainer.addSubview(actionBtn)
        
        logoutButton.frame = CGRect(x: 14, y: 210, width: expandedWidth - 28, height: 32)
        logoutButton.backgroundColor = UIColor(red: 0.65, green: 0.18, blue: 0.18, alpha: 0.15)
        logoutButton.layer.cornerRadius = 8.0
        logoutButton.layer.borderColor = UIColor(red: 0.75, green: 0.25, blue: 0.25, alpha: 0.4).cgColor
        logoutButton.layer.borderWidth = 1.0
        logoutButton.setTitle("Logout Session", for: .normal)
        logoutButton.setTitleColor(UIColor(red: 1.0, green: 0.45, blue: 0.45, alpha: 1.0), for: .normal)
        logoutButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        logoutButton.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)
        expandedContainer.addSubview(logoutButton)
    }
    
    private func setupGestures() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(pan)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tap.cancelsTouchesInView = false
        addGestureRecognizer(tap)
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        if currentState == .minimized {
            let point = gesture.location(in: self)
            if minimizedContainer.bounds.contains(point) {
                setExpanded(true, animated: true)
            }
        }
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let superview = superview else { return }
        let translation = gesture.translation(in: superview)
        
        switch gesture.state {
        case .began:
            touchOffset = center
        case .changed:
            center = CGPoint(x: touchOffset.x + translation.x, y: touchOffset.y + translation.y)
        case .ended, .cancelled:
            clampToScreenBoundsAnimated()
        default:
            break
        }
    }
    
    private func clampToScreenBoundsAnimated() {
        let screen = UIScreen.main.bounds
        let padding: CGFloat = 12.0
        let topPadding: CGFloat = 44.0
        
        var targetX = frame.origin.x
        var targetY = frame.origin.y
        
        if targetY < topPadding { targetY = topPadding }
        if targetY > screen.height - frame.height - padding { targetY = screen.height - frame.height - padding }
        
        if currentState == .minimized {
            let midX = screen.width / 2.0
            targetX = (center.x < midX) ? padding : (screen.width - frame.width - padding)
        } else {
            if targetX < padding { targetX = padding }
            if targetX > screen.width - frame.width - padding { targetX = screen.width - frame.width - padding }
        }
        
        let targetFrame = CGRect(x: targetX, y: targetY, width: frame.width, height: frame.height)
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseOut) {
            self.frame = targetFrame
        }
    }
    
    public func setExpanded(_ expanded: Bool, animated: Bool) {
        if expanded && currentState == .expanded { return }
        if !expanded && currentState == .minimized { return }
        
        currentState = expanded ? .expanded : .minimized
        let screen = UIScreen.main.bounds
        let currentCenter = center
        
        let newWidth = expanded ? expandedWidth : minimizedSize
        let newHeight = expanded ? expandedHeight : minimizedSize
        
        var newX = currentCenter.x - (newWidth / 2.0)
        var newY = currentCenter.y - (newHeight / 2.0)
        
        if newX < 12.0 { newX = 12.0 }
        if newX + newWidth > screen.width - 12.0 { newX = screen.width - newWidth - 12.0 }
        if newY < 44.0 { newY = 44.0 }
        if newY + newHeight > screen.height - 12.0 { newY = screen.height - newHeight - 12.0 }
        
        let newFrame = CGRect(x: newX, y: newY, width: newWidth, height: newHeight)
        
        if expanded {
            expandedContainer.isHidden = false
        } else {
            minimizedContainer.isHidden = false
        }
        
        let animationBlock = {
            self.frame = newFrame
            if expanded {
                self.minimizedContainer.alpha = 0.0
                self.expandedContainer.alpha = 1.0
            } else {
                self.minimizedContainer.alpha = 1.0
                self.expandedContainer.alpha = 0.0
            }
        }
        
        let completionBlock: (Bool) -> Void = { _ in
            if expanded {
                self.minimizedContainer.isHidden = true
            } else {
                self.expandedContainer.isHidden = true
                self.clampToScreenBoundsAnimated()
            }
            self.delegate?.floatingViewDidChangeState(self.currentState)
        }
        
        if animated {
            UIView.animate(withDuration: 0.32, delay: 0, usingSpringWithDamping: 0.82, initialSpringVelocity: 0.4, options: .curveEaseInOut, animations: animationBlock, completion: completionBlock)
        } else {
            animationBlock()
            completionBlock(true)
        }
    }
    
    @objc private func minimizeTapped() {
        setExpanded(false, animated: true)
    }
    
    public func updateStatus(status: String?, expiry: String?) {
        if let s = status { statusLabel.text = "● Status: \(s)" }
        if let e = expiry { expiryLabel.text = "Expires: \(e)" }
    }
    
    @objc private func moduleSwitchChanged(_ sender: UISwitch) {
        if sender.isOn {
            statusLabel.text = "● Status: Active & Authorized"
            statusLabel.textColor = UIColor(red: 0.25, green: 0.85, blue: 0.50, alpha: 1.0)
            minimizedStatusDot.backgroundColor = UIColor(red: 0.15, green: 0.85, blue: 0.40, alpha: 1.0)
        } else {
            statusLabel.text = "● Status: Paused"
            statusLabel.textColor = UIColor(red: 0.85, green: 0.65, blue: 0.20, alpha: 1.0)
            minimizedStatusDot.backgroundColor = UIColor(red: 0.85, green: 0.65, blue: 0.20, alpha: 1.0)
        }
        ModuleInterface.shared.executeFeatureAction(named: "toggleCoreState", parameters: ["active": sender.isOn])
    }
    
    @objc private func actionButtonTapped() {
        ModuleInterface.shared.executeFeatureAction(named: "triggerQuickAction", parameters: ["timestamp": Date().timeIntervalSince1970])
    }
    
    @objc private func logoutTapped() {
        delegate?.floatingViewDidRequestLogout(self)
    }
}
