//
//  HomeItemCell.swift
//  jSpringBoard
//
//  Created by Jota Melo on 15/06/17.
//  Copyright © 2017 jota. All rights reserved.
//

import UIKit

class HomeItemCellSnapshotView: UIView {
    
    var deleteButtonContainer: UIView?
    var badgeContainer: UIView
    var iconView: UIView
    var nameLabel: UIView
    var overlayView: UIView
    var badgeOverlayView: UIView?
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    required init(frame: CGRect, badgeContainer: UIView, iconView: UIView, nameLabel: UIView, overlayView: UIView, badgeOverlayView: UIView?) {
        
        self.badgeContainer = badgeContainer
        self.iconView = iconView
        self.nameLabel = nameLabel
        self.overlayView = overlayView
        self.badgeOverlayView = badgeOverlayView
        
        super.init(frame: frame)
        self.addSubview(iconView)
        self.addSubview(overlayView)
        self.addSubview(nameLabel)
        self.addSubview(badgeContainer)
        
        if let badgeOverlayView = badgeOverlayView {
            self.addSubview(badgeOverlayView)
        }
    }
}

protocol HomeItemCellDelegate: class {
    func didTapDelete(on cell: HomeItemCell)
}

class HomeItemCell: UICollectionViewCell {
    
    @IBOutlet var blur: UIVisualEffectView!
    @IBOutlet var deleteButton: UIButton!
    @IBOutlet var deleteButtonContainer: UIView!
    @IBOutlet var badgeLabel: UILabel?
    @IBOutlet var iconContainerView: UIView!
    @IBOutlet var iconImageView: UIImageView?
    @IBOutlet var nameLabel: UILabel?
    
    @IBOutlet var iconWidthConstraint: NSLayoutConstraint?
    @IBOutlet var iconTopConstraint: NSLayoutConstraint?
    @IBOutlet var nameLabelTopConstraint: NSLayoutConstraint?
    
    var highlightOverlayView: UIView?
    var badgeHighlightOverlayView: UIView?
    
    var liveIconView: UIView?
    
    override var isHighlighted: Bool {
        didSet {
            if self.highlightOverlayView == nil {
                self.createOverlayView()
            }
            
            if self.badgeHighlightOverlayView == nil {
                self.createBadgeOverlayView()
            }
            
            self.highlightOverlayView?.alpha = self.isHighlighted ? 0.4 : 0
            
            if self.item?.badge != nil {
                self.badgeHighlightOverlayView?.alpha = self.highlightOverlayView!.alpha
            }
        }
    }
    
    weak var delegate: HomeItemCellDelegate?
    var item: HomeItem? {
        didSet {
            self.updateUI()
        }
    }
    
    var isAnimating = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.clipsToBounds = false
        self.iconContainerView.applyIconMask()
        self.iconImageView?.isUserInteractionEnabled = true
        self.deleteButtonContainer?.transform = CGAffineTransform.identity.scaledBy(x: 0.0001, y: 0.0001)
    }
    
    func createOverlayView() {
        
        let highlightOverlayView = UIView(frame: self.iconContainerView.frame)
        highlightOverlayView.backgroundColor = .black
        highlightOverlayView.alpha = 0
        highlightOverlayView.applyIconMask()
        self.contentView.insertSubview(highlightOverlayView, aboveSubview: self.iconContainerView)
        
        self.highlightOverlayView?.removeFromSuperview()
        self.highlightOverlayView = highlightOverlayView
    }
    
    func createBadgeOverlayView() {
        guard let badgeLabelContainer = self.badgeLabel?.superview, self.item?.badge != nil else {
            self.badgeHighlightOverlayView?.removeFromSuperview()
            self.badgeHighlightOverlayView = nil
            return
        }
        
        let highlightOverlayView = UIView()
        highlightOverlayView.backgroundColor = .black
        highlightOverlayView.alpha = 0
        highlightOverlayView.layer.cornerRadius = badgeLabelContainer.layer.cornerRadius
        highlightOverlayView.layer.masksToBounds = true
        highlightOverlayView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(highlightOverlayView)
        
        let topConstraint = badgeLabelContainer.topAnchor.constraint(equalTo: highlightOverlayView.topAnchor)
        let rightConstraint = badgeLabelContainer.rightAnchor.constraint(equalTo: highlightOverlayView.rightAnchor)
        let bottomConstraint = badgeLabelContainer.bottomAnchor.constraint(equalTo: highlightOverlayView.bottomAnchor)
        let leftConstraint = badgeLabelContainer.leftAnchor.constraint(equalTo: highlightOverlayView.leftAnchor)
        self.contentView.addConstraints([topConstraint, rightConstraint, bottomConstraint, leftConstraint])
        
        self.badgeHighlightOverlayView?.removeFromSuperview()
        self.badgeHighlightOverlayView = highlightOverlayView
    }
    
    func updateUI() {
        guard let item = self.item else { return }
        
        if let badge = item.badge {
            self.badgeLabel?.superview?.isHidden = false
            if badge == 0 {
                self.badgeLabel?.text = ""
            } else {
                self.badgeLabel?.text = "\(badge)"
            }
        } else {
            self.badgeLabel?.superview?.isHidden = true
        }
        
        self.nameLabel?.text = item.name
        self.nameLabel?.alpha = 1
        
        NotificationCenter.default.removeObserver(self)
        if let app = item as? App {
            var liveView: UIView?
            if app.bundleID == "com.apple.compass" {
                liveView = CompassIconView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
            } else if app.bundleID == "com.apple.mobiletimer" {
                liveView = ClockIconView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
            }
            
            if app.bundleID == "com.apple.mobilecal" {
                NotificationCenter.default.addObserver(self, selector: #selector(updateIcon), name: .UIApplicationSignificantTimeChange, object: nil)
            }
            
            self.updateIcon()
            self.liveIconView?.removeFromSuperview()
            if let liveView = liveView {
                self.setup(liveView: liveView)
            }
        }
    }
    
    @objc func updateIcon() {
        guard let app = self.item as? App else { return }
        if let icon = app.icon {
            self.iconImageView?.image = icon
        } else {
            self.iconImageView?.image = #imageLiteral(resourceName: "default-icon")
        }
    }
    
    func setup(liveView: UIView) {
        
        liveView.translatesAutoresizingMaskIntoConstraints = false
        
        self.contentView.insertSubview(liveView, aboveSubview: self.iconContainerView)
        let centerYConstraint = self.iconContainerView.centerYAnchor.constraint(equalTo: liveView.centerYAnchor)
        let centerXConstraint = self.iconContainerView.centerXAnchor.constraint(equalTo: liveView.centerXAnchor)
        self.contentView.addConstraints([centerYConstraint, centerXConstraint])
        
        let widthConstraint = liveView.widthAnchor.constraint(equalToConstant: 60)
        let heightConstraint = liveView.heightAnchor.constraint(equalToConstant: 60)
        liveView.addConstraints([widthConstraint, heightConstraint])
        
        if liveView.frame.width != self.iconContainerView.frame.width {
            let scaleFactor = self.iconContainerView.frame.width / liveView.frame.width
            liveView.transform = CGAffineTransform.identity.scaledBy(x: scaleFactor, y: scaleFactor)
        }
        
        liveView.applyIconMask()
        self.liveIconView = liveView
    }
    
    func animate(force: Bool = false) {
        guard !self.isAnimating || force else { return }
        
        self.isAnimating = true
        
        // MY GOD THIS FUCKING ANIMATION
        // This was one of the first things I actually did on the project,
        // just after getting the app grid right. I started with a simple
        // rotate, so the view would just rock back and forth and I immediatly
        // realized that SpringBoard's animation was actually much more complex
        // than that, the apps were alive and dancing everywhere.
        // I couldn't get it right so for a long time I left it with the simple
        // rotate, and it was the thing that most bugged me about the app, this
        // animation just didn't look right. But then one night after finishing
        // the 3D Touch stuff I decided to try and Google again to see if anyone
        // had even tried to figure out the actual animation. And it was a good search!
        // I found this awesome guy who reverse engineered SpringBoard and got the
        // exact animation, and it worked perfectly. Happy night this was.
        // ref: https://stackoverflow.com/a/35043259/1757960
        
        let positionAnimation = CAKeyframeAnimation(keyPath: "position")
        positionAnimation.values = [CGPoint(x: -1, y: -1),
                                    CGPoint(x: 0, y: 0),
                                    CGPoint(x: -1, y: 0),
                                    CGPoint(x: 0, y: -1),
                                    CGPoint(x: -1, y: -1)]
        positionAnimation.calculationMode = "linear"
        positionAnimation.isAdditive = true
        
        let transformAnimation = CAKeyframeAnimation(keyPath: "transform")
        transformAnimation.valueFunction = CAValueFunction(name: kCAValueFunctionRotateZ)
        transformAnimation.values = [-0.03525565, 0.03525565, -0.03525565]
        transformAnimation.calculationMode = "linear"
        transformAnimation.isAdditive = true
        
        let animationGroup = CAAnimationGroup()
        animationGroup.duration = 0.25
        animationGroup.repeatCount = .infinity
        animationGroup.isRemovedOnCompletion = false
        animationGroup.beginTime = Double(arc4random() % 25) / 100.0
        animationGroup.animations = [positionAnimation, transformAnimation]
        animationGroup.isRemovedOnCompletion = false
        
        self.contentView.layer.add(animationGroup, forKey: "jitterAnimation")
    }
    
    func stopAnimation() {
        
        self.isAnimating = false
        self.contentView.layer.removeAllAnimations()
        self.contentView.transform = .identity
    }
    
    func enterEditingMode() {
        UIView.animate(withDuration: 0.25) {
            self.deleteButtonContainer?.transform = .identity
        }
    }
    
    func leaveEditingMode() {
        UIView.animate(withDuration: 0.25) {
            self.deleteButtonContainer?.transform = CGAffineTransform.identity.scaledBy(x: 0.0001, y: 0.0001)
        }
    }
    
    func snapshotView() -> HomeItemCellSnapshotView {
        
        if self.highlightOverlayView == nil {
            self.createOverlayView()
        }
        
        let iconContainerSnapshot = self.iconContainerView.snapshotView(afterScreenUpdates: true)!
        iconContainerSnapshot.frame = self.iconContainerView.frame
        
        let badgeContainerSnapshot = self.badgeLabel!.superview!.snapshotView(afterScreenUpdates: true)!
        badgeContainerSnapshot.frame = self.badgeLabel!.superview!.frame
        
        let nameLabelSnapshot = self.nameLabel!.snapshotView(afterScreenUpdates: true)!
        nameLabelSnapshot.frame = self.nameLabel!.frame
        
        let overlaySnapshot = self.highlightOverlayView!.snapshotView(afterScreenUpdates: true)!
        overlaySnapshot.frame = self.highlightOverlayView!.frame
        
        var badgeOverlaySnapshot: UIView?
        if let badgeOverlayView = self.badgeHighlightOverlayView {
            badgeOverlaySnapshot = badgeOverlayView.snapshotView(afterScreenUpdates: true)
            badgeOverlaySnapshot?.frame = badgeOverlayView.frame
        }
        
        let snapshotView = HomeItemCellSnapshotView(frame: self.bounds, badgeContainer: badgeContainerSnapshot, iconView: iconContainerSnapshot, nameLabel: nameLabelSnapshot, overlayView: overlaySnapshot, badgeOverlayView: badgeOverlaySnapshot)
        
        if let deleteButtonContainer = self.deleteButtonContainer {
            let originalTransform = deleteButtonContainer.transform
            self.deleteButtonContainer.transform = .identity
            
            let deleteButtonContainerSnapshot = self.deleteButtonContainer.snapshotView(afterScreenUpdates: true)!
            deleteButtonContainerSnapshot.frame = deleteButtonContainer.frame
            deleteButtonContainerSnapshot.transform = originalTransform
            snapshotView.deleteButtonContainer = deleteButtonContainerSnapshot
            snapshotView.addSubview(deleteButtonContainerSnapshot)
            
            self.deleteButtonContainer.transform = originalTransform
        }
        
        return snapshotView
    }
    
    @IBAction func deleteAction() {
        self.delegate?.didTapDelete(on: self)
    }
}

extension UIView {
    
    func applyIconMask() {
        
        let mask = CALayer()
        mask.contents = #imageLiteral(resourceName: "AppIconMask").cgImage
        mask.frame = self.bounds
        self.layer.mask = mask
        self.layer.masksToBounds = true
    }
    
    func applyIconMaskView() {
        
        let maskLayer = CALayer()
        maskLayer.contents = #imageLiteral(resourceName: "AppIconMask").cgImage
        maskLayer.frame = self.bounds
        
        let maskView = UIView(frame: self.bounds)
        maskView.backgroundColor = .black
        maskView.layer.mask = maskLayer
        
        self.mask = maskView
    }
}
