//
//  FolderViewController.swift
//  jSpringBoard
//
//  Created by Jota Melo on 15/06/17.
//  Copyright © 2017 jota. All rights reserved.
//

import UIKit

protocol FolderViewControllerDelegate: class {
    func openAnimationWillStart(on viewController: FolderViewController)
    func didChange(name: String, on viewController: FolderViewController)
    func didSelect(app: App, on viewController: FolderViewController)
    func didEnterEditingMode(on viewController: FolderViewController)
    func didBeginFolderDragOut(withTransfer transfer: AppDragOperationTransfer, on viewController: FolderViewController)
    func dismissAnimationWillStart(currentPage: Int, updatedPages: [[App]], on viewController: FolderViewController)
    func dismissAnimationDidFinish(on viewController: FolderViewController)
}

class FolderViewController: UIViewController {
    
    @IBOutlet var nameTextFieldContainer: UIView!
    @IBOutlet var nameTextFieldConstraintCenterYConstraint: NSLayoutConstraint!
    @IBOutlet var nameTextField: UITextField!
    @IBOutlet var clearButton: UIButton!
    
    @IBOutlet var containerView: UIView!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var blurView: UIVisualEffectView!
    
    @IBOutlet var containerViewCenterXConstraint: NSLayoutConstraint!
    @IBOutlet var containerViewCenterYConstraint: NSLayoutConstraint!
    @IBOutlet var containerViewWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet var placeholderBackgroundView: UIView!
    @IBOutlet var placeholderBackgroundBlurView: UIVisualEffectView!
    @IBOutlet var placeholderBackgroundViewLeftConstraint: NSLayoutConstraint!
    @IBOutlet var placeholderBackgroundViewTopConstraint: NSLayoutConstraint!
    
    @IBOutlet var placeholderView: UIView!
    @IBOutlet var placeholderViewIcons: [UIImageView]!
    @IBOutlet var placeholderViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet var placeholderViewTopConstraint: NSLayoutConstraint!
    @IBOutlet var placeholderViewLeftConstraint: NSLayoutConstraint!
    
    @IBOutlet var placeholderViewRowTopConstraint: NSLayoutConstraint!
    @IBOutlet var placeholderViewRowRightConstraint: NSLayoutConstraint!
    @IBOutlet var placeholderViewRowLeftConstraint: NSLayoutConstraint!
    @IBOutlet var placeholderViewRowBottomConstraints: [NSLayoutConstraint]!
    
    @IBOutlet var placeholderViewRowItemWidthConstraint: NSLayoutConstraint!
    @IBOutlet var placeholderViewRowItemTopConstraints: [NSLayoutConstraint]!
    @IBOutlet var placeholderViewRowItemLeftConstraints: [NSLayoutConstraint]!
    @IBOutlet var placeholderViewRowLastItemRightConstraints: [NSLayoutConstraint]!
    
    @IBOutlet var pageControl: UIPageControl!
    
    var openAnimationDidEndBlock: (() -> Void)?
    
    weak var delegate: FolderViewControllerDelegate?
    var folder: Folder!
    var sourcePoint: CGPoint!
    var startInRename: Bool = false
    var currentPage: Int = 0
    var dragOperationTransfer: AppDragOperationTransfer?
    
    private var gridManager: AppGridManager!
    private var containerViewOriginalFrame: CGRect!
    private var blurEffet: UIBlurEffect!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.nameTextField.text = self.folder.name
        self.leaveTextFieldEditingMode()
        
        self.gridManager = AppGridManager(viewController: self, mainCollectionView: self.collectionView, items: self.folder.pages)
        self.gridManager.delegate = self
        
        if self.gridManager.items.count == 1 {
            self.pageControl.isHidden = true
        } else {
            self.pageControl.alpha = 0
            self.pageControl.isHidden = false
            self.pageControl.numberOfPages = self.gridManager.items.count
        }
        
        if let transfer = self.dragOperationTransfer {
            self.gridManager.perform(transfer: transfer)
        }
        
        if self.isEditing {
            let indexPath = IndexPath(item: self.currentPage, section: 0)
            self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
        }
        
        self.setupPlaceholder(forPage: self.currentPage)
        self.setupContainerView()
        self.setupBlur()
        
        self.dragOperationTransfer = nil
        
        NotificationCenter.default.addObserver(self, selector: #selector(homeTapped), name: .homeTapped, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(homeDoubleTapped), name: .homeDoubleTapped, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if #available(iOS 11, *) {
            self.placeholderBackgroundBlurView.applyIconMask()
        } else {
            self.placeholderBackgroundBlurView.applyIconMaskView()
        }
        self.placeholderBackgroundView.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.animateIn()
        
        if self.isEditing {
            self.gridManager.enterEditingMode(suppressHaptic: true)
        }
    }
    
    func setupPlaceholder(forPage page: Int) {
        
        self.placeholderViewTopConstraint.constant = self.sourcePoint.y
        self.placeholderViewLeftConstraint.constant = self.sourcePoint.x
        
        self.placeholderBackgroundViewTopConstraint.constant = self.sourcePoint.y
        self.placeholderBackgroundViewLeftConstraint.constant = self.sourcePoint.x
        
        let page = self.gridManager.items[page]
        for (index, imageView) in self.placeholderViewIcons.sorted(by: { $0.tag < $1.tag }).enumerated() {
            if index > page.count - 1 {
                imageView.isHidden = true
                continue
            }
            
            if let app = page[index] as? App {
                if let draggedItem = self.dragOperationTransfer?.operation.item, draggedItem === app {
                    imageView.isHidden = true
                } else {
                    imageView.image = MaskedIconCache.shared.maskedIcon(for: app)
                    imageView.isHidden = false
                }
            }
        }
    }
    
    func setupContainerView() {
        
        self.view.layoutIfNeeded()
        
        self.containerViewOriginalFrame = self.containerView.frame
        self.containerView.transform = CGAffineTransform.transform(rect: self.containerView.frame, to: self.placeholderView.frame)
        self.containerView.alpha = 0
    }
    
    func setupBlur() {
        
        let blurEffect = (NSClassFromString("_UICustomBlurEffect") as! UIBlurEffect.Type).init()
        blurEffect.setValue(1, forKeyPath: "scale")
        blurEffect.setValue(0, forKeyPath: "blurRadius")
        self.blurView.effect = blurEffect
        self.blurEffet = blurEffect
    }
    
    func leaveTextFieldEditingMode() {
        
        self.nameTextField.isEnabled = false
        self.clearButton.alpha = 0
        self.nameTextFieldContainer.backgroundColor = self.nameTextFieldContainer.backgroundColor?.withAlphaComponent(0)
    }
    
    func enterTextFieldEditingMode() {
        
        self.nameTextField.isEnabled = true
        self.clearButton.alpha = 1
        self.nameTextFieldContainer.backgroundColor = self.nameTextFieldContainer.backgroundColor?.withAlphaComponent(0.4)
    }
    
    func animateIn() {
        
        self.delegate?.openAnimationWillStart(on: self)
        
        self.placeholderBackgroundView.isHidden = false
        
        self.placeholderViewWidthConstraint.constant = self.containerViewOriginalFrame.width
        self.placeholderViewTopConstraint.constant = self.containerViewOriginalFrame.minY
        self.placeholderViewLeftConstraint.constant = self.containerViewOriginalFrame.minX
        
        self.placeholderViewRowTopConstraint.constant = 14
        self.placeholderViewRowLeftConstraint.constant = 26.5
        self.placeholderViewRowRightConstraint.constant = 26.5
        self.placeholderViewRowBottomConstraints.forEach { $0.constant = 17 }
        
        self.placeholderViewRowItemWidthConstraint.constant = 60
        self.placeholderViewRowItemTopConstraints.forEach { $0.constant = 12 }
        self.placeholderViewRowItemLeftConstraints.forEach { $0.constant = 9 }
        self.placeholderViewRowLastItemRightConstraints.forEach { $0.constant = 9 }
        
        let animation = UIViewPropertyAnimator(duration: 0.35, controlPoint1: CGPoint(x: 0.37, y: 0.13), controlPoint2: CGPoint(x: 0, y: 1)) {
            self.view.layoutIfNeeded()
            
            self.containerView.transform = CGAffineTransform.identity
            self.containerView.alpha = 1
            
            self.gridManager.updateFolderDragOutFlags()
            
            self.placeholderBackgroundView.transform = CGAffineTransform.transform(rect: self.placeholderBackgroundView.frame, to: self.containerViewOriginalFrame)
            self.placeholderBackgroundBlurView.effect = nil
            self.placeholderView.alpha = 0
            
            self.blurEffet.setValue(15, forKeyPath: "blurRadius")
            self.blurEffet.setValue(1.5, forKey: "saturationDeltaFactor")
            self.blurView.effect = self.blurEffet
        }
        animation.addCompletion { _ in
            self.placeholderView.alpha = 0
            self.openAnimationDidEndBlock?()
            
            UIViewPropertyAnimator(duration: 0.5, curve: .easeOut, animations: {
                self.nameTextField.alpha = 1
                self.pageControl.alpha = 1
                
                if self.isEditing {
                    self.enterTextFieldEditingMode()
                    
                    if self.startInRename {
                        self.nameTextField.becomeFirstResponder()
                        self.nameTextField.selectAll(nil)
                    }
                }
            }).startAnimation()
        }
        animation.startAnimation()
    }
    
    func toggleReachability(completion: (() -> ())? = nil) {
        
        if self.nameTextFieldConstraintCenterYConstraint.isActive {
            NSLayoutConstraint.deactivate([self.nameTextFieldConstraintCenterYConstraint])
            let constraintValue = -(self.nameTextFieldContainer.superview!.frame.height - self.nameTextFieldContainer.frame.maxY)
            let bottomConstraint = self.nameTextFieldContainer.bottomAnchor.constraint(equalTo: self.nameTextFieldContainer.superview!.bottomAnchor, constant: constraintValue)
            self.nameTextFieldContainer.superview?.addConstraint(bottomConstraint)
            self.view.layoutIfNeeded()
        }
        
        let animation = UIViewPropertyAnimator(duration: 0.35, controlPoint1: CGPoint(x: 0.25, y: 0.10), controlPoint2: CGPoint(x: 0.54, y: 0.89)) {
            if self.containerViewCenterYConstraint.constant == 0 {
                self.containerViewCenterYConstraint.constant = self.view.frame.height / 4
            } else {
                self.containerViewCenterYConstraint.constant = 0
            }
            
            self.view.layoutIfNeeded()
        }
        animation.addCompletion { _ in
            completion?()
        }
        animation.startAnimation()
    }
    
    @objc func homeTapped() {
        
        if self.containerViewCenterYConstraint.constant != 0 {
            self.toggleReachability()
        } else if self.isEditing {
            self.isEditing = false
            self.gridManager.homeAction()
            
            self.nameTextField.resignFirstResponder()
            UIView.animate(withDuration: 0.25, animations: {
                self.leaveTextFieldEditingMode()
            })
        } else {
            self.dismiss(nil)
        }
    }
    
    @objc func homeDoubleTapped() {
        self.toggleReachability()
    }
    
    @IBAction func clearTextField(_ sender: Any) {
        self.nameTextField.text = ""
        self.nameTextField.becomeFirstResponder()
    }
    
    @IBAction func dismiss(_ sender: Any?) {
        
        if self.containerViewCenterYConstraint.constant != 0 {
            self.toggleReachability(completion: {
                self.dismiss(sender)
            })
            return
        }
        
        NotificationCenter.default.removeObserver(self)
        
        self.nameTextField.resignFirstResponder()
        
        self.placeholderViewWidthConstraint.constant = 60
        self.placeholderViewTopConstraint.constant = self.sourcePoint.y
        self.placeholderViewLeftConstraint.constant = self.sourcePoint.x
        
        self.placeholderViewRowTopConstraint.constant = 7.5
        self.placeholderViewRowLeftConstraint.constant = 7.5
        self.placeholderViewRowRightConstraint.constant = 7.5
        self.placeholderViewRowBottomConstraints.forEach { $0.constant = 3 }
        
        self.placeholderViewRowItemWidthConstraint.constant = 13
        self.placeholderViewRowItemTopConstraints.forEach { $0.constant = 0 }
        self.placeholderViewRowItemLeftConstraints.forEach { $0.constant = 0 }
        self.placeholderViewRowLastItemRightConstraints.forEach { $0.constant = 0 }
        
        self.setupPlaceholder(forPage: self.pageControl.currentPage)
        self.gridManager.leaveEditingMode()
        
        self.delegate?.dismissAnimationWillStart(currentPage: self.pageControl.currentPage, updatedPages: self.gridManager.items as! [[App]], on: self)
        let animation = UIViewPropertyAnimator(duration: 0.35, controlPoint1: CGPoint(x: 0.37, y: 0.13), controlPoint2: CGPoint(x: 0, y: 1)) {
            self.view.layoutIfNeeded()
            
            self.nameTextField.alpha = 0
            self.leaveTextFieldEditingMode()
            
            self.containerView.transform = CGAffineTransform.transform(rect: self.containerView.frame, to: self.placeholderView.frame)
            self.containerView.alpha = 0
            
            self.placeholderView.alpha = 1
            self.placeholderBackgroundView.transform = .identity
            self.placeholderBackgroundBlurView.effect = UIBlurEffect(style: .light)
            
            self.blurEffet.setValue(0, forKeyPath: "blurRadius")
            self.blurEffet.setValue(1, forKey: "saturationDeltaFactor")
            self.blurView.effect = self.blurEffet
        }
        animation.addCompletion { _ in
            self.delegate?.dismissAnimationDidFinish(on: self)
            self.gridManager = nil
        }
        animation.startAnimation()
    }
}

// MARK: - App Grid Manager delegate

extension FolderViewController: AppGridManagerDelegate {
    
    func didUpdate(pageCount: Int, on manager: AppGridManager) {
        self.pageControl.numberOfPages = pageCount
    }
    
    func didMove(toPage page: Int, on manager: AppGridManager) {
        self.pageControl.currentPage = page
    }
    
    func didEnterEditingMode(on manager: AppGridManager) {
        
        if !self.isEditing {
            self.delegate?.didEnterEditingMode(on: self)
            self.isEditing = true
        }
        
        if self.pageControl.isHidden {
            self.pageControl.isHidden = false
            self.pageControl.alpha = 0
        }
        
        UIView.animate(withDuration: 0.25) {
            self.enterTextFieldEditingMode()
            
            self.pageControl.numberOfPages = self.gridManager.items.count
            self.pageControl.alpha = 1
        }
    }
    
    func didBeginFolderDragOut(transfer: AppDragOperationTransfer, on manager: AppGridManager) {
        
        self.dismiss(manager)
        self.delegate?.didBeginFolderDragOut(withTransfer: transfer, on: self)
    }
    
    func didDelete(item: HomeItem, on manager: AppGridManager) {
        
        if self.gridManager.items.reduce(0, { $0 + $1.count }) == 0 {
            self.dismiss(nil)
        }
    }
    
    func didSelect(app: App, on manager: AppGridManager) {
        self.delegate?.didSelect(app: app, on: self)
    }
    
    func collectionViewDidScroll(_ collectionView: UICollectionView, on manager: AppGridManager) { }
    
    func didUpdateItems(on manager: AppGridManager) { }
    
    func openSettings(fromSnapshotView snapshotView: UIView, on manager: AppGridManager) { }
}

// MARK: - Text Field delegate

extension FolderViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        if !textField.hasText {
            textField.text = self.folder.name
        } else if let text = textField.text {
            self.folder.name = text
            self.delegate?.didChange(name: text, on: self)
        }
        
        return true
    }
}

// MARK: - Helpers

extension CGAffineTransform {
    
    static func transform(rect fromRect: CGRect, to toRect: CGRect) -> CGAffineTransform {
        
        let scaleWidth = toRect.width / fromRect.width
        let scaleHeight = toRect.height / fromRect.height
        let transform = CGAffineTransform.identity.translatedBy(x: toRect.midX - fromRect.midX, y: toRect.midY - fromRect.midY)
        return transform.scaledBy(x: scaleWidth, y: scaleHeight)
    }
}
