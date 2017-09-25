//
//  VirtualHomeButtonManager.swift
//  jSpringBoard
//
//  Created by Jota Melo on 22/07/17.
//  Copyright © 2017 jota. All rights reserved.
//

import UIKit

extension Notification.Name {
    static let homeTapped = Notification.Name("homeTapped")
    static let homeDoubleTapped = Notification.Name("homeDoubleTapped")
}

class VirtualHomeButtonManager {
    
    private var containerView: UIView
    private var homeButtonContainer: UIView
    private var dragOffset: CGSize = .zero
    private var fadeOutTimer: Timer?
    private var frameBeforeKeyboardShow: CGRect?
    
    required init(view: UIView) {
        
        let buttonSize = Settings.shared.homeButtonSize
        
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blurView.frame = CGRect(x: 0, y: 0, width: buttonSize, height: buttonSize)
        
        if #available(iOS 11, *) {
            blurView.applyIconMask()
        } else {
            blurView.applyIconMaskView()
        }
        
        let centerImage = #imageLiteral(resourceName: "NubbitCenter")
        let centerImageView = UIImageView(frame: CGRect(x: (buttonSize - centerImage.size.width) / 2, y: (buttonSize - centerImage.size.height) / 2, width: centerImage.size.width, height: centerImage.size.height))
        centerImageView.image = centerImage
        
        self.homeButtonContainer = UIView(frame: CGRect(x: view.frame.size.width - buttonSize - Settings.shared.homeButtonMargin, y: 89, width: buttonSize, height: buttonSize))
        self.homeButtonContainer.alpha = Settings.shared.homeButtonInactiveAlpha
        self.homeButtonContainer.addSubview(blurView)
        self.homeButtonContainer.addSubview(centerImageView)
        
        let panGestureRecognizer = UIPanGestureRecognizer()
        self.homeButtonContainer.addGestureRecognizer(panGestureRecognizer)
        
        let tapRecognizer = UITapGestureRecognizer()
        self.homeButtonContainer.addGestureRecognizer(tapRecognizer)
        
        let doubleTapRecognizer = UITapGestureRecognizer()
        doubleTapRecognizer.numberOfTapsRequired = 2
        self.homeButtonContainer.addGestureRecognizer(doubleTapRecognizer)
        
        self.containerView = view
        self.containerView.addSubview(self.homeButtonContainer)
        
        defer {
            panGestureRecognizer.addTarget(self, action: #selector(panHandler(_:)))
            tapRecognizer.addTarget(self, action: #selector(tapHandler))
            doubleTapRecognizer.addTarget(self, action: #selector(doubleTapHandler))
            tapRecognizer.require(toFail: doubleTapRecognizer)
            
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow(_:)), name: .UIKeyboardDidShow, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide), name: .UIKeyboardDidHide, object: nil)
        }
    }
    
    func startFadeOutTimer() {
        
        self.fadeOutTimer = Timer.scheduledTimer(withTimeInterval: 4, repeats: false, block: { timer in
            UIView.animate(withDuration: 0.25, animations: {
                self.homeButtonContainer.alpha = Settings.shared.homeButtonInactiveAlpha
            })
        })
    }
    
    @objc func panHandler(_ gestureRecognizer: UIPanGestureRecognizer) {
        
        self.fadeOutTimer?.invalidate()
        let touchPoint = gestureRecognizer.location(in: self.containerView)
        
        switch gestureRecognizer.state {
        case .began:
            self.dragOffset = CGSize(width: self.homeButtonContainer.center.x - touchPoint.x, height: self.homeButtonContainer.center.y - touchPoint.y)
            
            UIView.animate(withDuration: 0.25, animations: {
                self.homeButtonContainer.alpha = 1
            })
        case .changed:
            var offsettedTouchPoint = touchPoint
            offsettedTouchPoint.x += self.dragOffset.width
            offsettedTouchPoint.y += self.dragOffset.height
            self.homeButtonContainer.center = offsettedTouchPoint
        default:
            let newFrame: CGRect
            let margin = Settings.shared.homeButtonMargin
            let size = Settings.shared.homeButtonSize
            if touchPoint.y < 64 {
                newFrame = CGRect(x: self.homeButtonContainer.frame.minX, y: margin, width: size, height: size)
            } else if touchPoint.y > self.containerView.frame.height - 64 {
                newFrame = CGRect(x: self.homeButtonContainer.frame.minX, y: self.containerView.frame.height - size - margin, width: size, height: size)
            } else if touchPoint.x < self.containerView.frame.width / 2 {
                newFrame = CGRect(x: margin, y: self.homeButtonContainer.frame.minY, width: size, height: size)
            } else {
                newFrame = CGRect(x: self.containerView.frame.width - size - margin, y: self.homeButtonContainer.frame.minY, width: size, height: size)
            }
            
            UIView.animate(withDuration: 0.25, animations: {
                self.homeButtonContainer.frame = newFrame
            })
            
            self.startFadeOutTimer()
            self.frameBeforeKeyboardShow = nil
        }
    }
    
    @objc func tapHandler() {
        
        NotificationCenter.default.post(name: .homeTapped, object: nil)
        
        self.fadeOutTimer?.invalidate()
        UIView.animate(withDuration: 0.25, animations: {
            self.homeButtonContainer.alpha = 1
        })
        self.startFadeOutTimer()
    }
    
    @objc func doubleTapHandler() {
        
        NotificationCenter.default.post(name: .homeDoubleTapped, object: nil)
        
        self.fadeOutTimer?.invalidate()
        UIView.animate(withDuration: 0.25, animations: {
            self.homeButtonContainer.alpha = 1
        })
        self.startFadeOutTimer()
    }
    
    @objc func keyboardDidShow(_ notification: Notification) {
        
        let keyboardFrame = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as! CGRect
        if self.homeButtonContainer.frame.minY > keyboardFrame.minY {
            self.frameBeforeKeyboardShow = self.homeButtonContainer.frame
            UIView.animate(withDuration: 0.25, animations: {
                self.homeButtonContainer.frame = self.homeButtonContainer.frame.offsetBy(dx: 0, dy: -(self.homeButtonContainer.frame.maxY - keyboardFrame.minY))
            })
        }
    }
    
    @objc func keyboardDidHide() {
        
        if let previousFrame = self.frameBeforeKeyboardShow {
            UIView.animate(withDuration: 0.25, animations: {
                self.homeButtonContainer.frame = previousFrame
            })
        }
    }
}
