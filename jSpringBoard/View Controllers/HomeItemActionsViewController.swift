//
//  HomeItemActionsViewController.swift
//  jSpringBoard
//
//  Created by Jota Melo on 23/07/17.
//  Copyright © 2017 jota. All rights reserved.
//

import UIKit

enum ActionsMenuHorizontalPosition {
    case left
    case right
    case center
}

enum ActionsMenuVerticalPosition {
    case top
    case bottom
}

protocol HomeItemActionsViewControllerDelegate: class {
    func didSelect(itemAction: HomeItemAction, on viewController: HomeItemActionsViewController)
    func homeItemActionsViewControllerDidDismiss(_ viewController: HomeItemActionsViewController)
}

class HomeItemActionsViewController: UIViewController {
    
    @IBOutlet var blurView: UIVisualEffectView!
    @IBOutlet var vibrancyView: UIVisualEffectView!
    @IBOutlet var tableVibrancyView: UIVisualEffectView!
    @IBOutlet var itemsContainerView: JMView!
    @IBOutlet var itemsContainerViewBackground: UIView!
    @IBOutlet var tableView: UITableView!
    
    @IBOutlet var tableViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet var itemsContainerViewTopConstraint: NSLayoutConstraint!
    @IBOutlet var itemsContainerViewLeftConstraint: NSLayoutConstraint!
    
    @IBOutlet var itemsContainerViewBackgroundTopConstraint: NSLayoutConstraint!
    @IBOutlet var itemsContainerViewBackgroundLeftConstraint: NSLayoutConstraint!
    @IBOutlet var itemsContainerViewBackgroundWidthConstraint: NSLayoutConstraint!
    @IBOutlet var itemsContainerViewBackgroundHeightConstraint: NSLayoutConstraint!
    
    weak var delegate: HomeItemActionsViewControllerDelegate?
    var itemView: HomeItemCellSnapshotView!
    var item: HomeItem!
    var horizontalPosition: ActionsMenuHorizontalPosition = .right
    var verticalPosition: ActionsMenuVerticalPosition = .bottom
    var viewDidAppearBlock: (() -> Void)?
    var willDismissBlock: (() -> Void)?
    
    private var blurEffect: UIBlurEffect!
    private var cellBackgroundView: UIView!
    private var iconViewFrame: CGRect!
    private var notificationFeedbackGenerator = UINotificationFeedbackGenerator()
    private var impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private var selectionFeedbackGenerator = UISelectionFeedbackGenerator()
    private var isPresentingOptions = false
    private var currentSelectedCell: HomeItemActionCell?
    private var viewsMovedOutOfVibrancy: [UIView] = []
    private var items: [HomeItemAction] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.itemsContainerViewBackground.isHidden = true
        
        self.setupDataSource()
        
        self.tableViewHeightConstraint.constant = self.tableView.rowHeight * CGFloat(self.items.count)
        self.view.layoutIfNeeded()
        
        self.moveColoredViewsOutOfVibrancy()
        self.setupForAnimation()
        self.setupPosition()
        self.setupBlur()
        
        self.view.addSubview(self.itemView)
        self.notificationFeedbackGenerator.prepare()
        self.impactFeedbackGenerator.prepare()
        
        self.tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: 1))
        self.tableView.reloadData()
        
        self.cellBackgroundView = UIView(frame: CGRect(x: 0, y: 0, width: 414, height: 62))
        self.cellBackgroundView.backgroundColor = .white
        self.cellBackgroundView.alpha = 0
        self.tableVibrancyView.superview!.insertSubview(self.cellBackgroundView, belowSubview: self.tableVibrancyView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.viewDidAppearBlock?()
    }
    
    func setupDataSource() {
        guard self.item.isShareable else { return }
        
        if let app = self.item as? App {
            let shareItem = HomeItemAction(icon: #imageLiteral(resourceName: "SBSApplicationShortcutSystemIcon_Share"), title: NSLocalizedString("Share \(app.name)", comment: ""), badge: nil)
            self.items = [shareItem, shareItem, shareItem, shareItem, shareItem]
        } else if let folder = self.item as? Folder {
            for app in folder.pages.flatMap({ $0 }) {
                if app.badge != nil {
                    let item = AppAction(app: app)
                    self.items.append(item)
                }
            }
            
            let renameItem = HomeItemAction(icon: #imageLiteral(resourceName: "SBSApplicationShortcutSystemIcon_ComposeNew"), title: NSLocalizedString("Rename", comment: ""), badge: nil)
            self.items.append(renameItem)
        }
    }
    
    func moveColoredViewsOutOfVibrancy() {
        
        // In Brazil we call this a GAMBIARRA
        // Views like the app icon and badge container (both always present together)
        // look REALLY weird inside the UIVisualEffectView with the vibrancy effect
        // Doesn't seem possible to disable the effect for just a view or something,
        // so we'll just bring them to the superview, in the same position
        for cell in self.tableView.visibleCells {
            guard let cell = cell as? HomeItemActionCell, let item = cell.item, item.badge != nil else { continue }
            
            let iconFrame = self.tableView.convert(cell.iconImageView.frame, from: cell)
            let badgeFrame = self.tableView.convert(cell.badgeLabel.superview!.frame, from: cell)
            
            let iconSnapshotView = cell.iconImageView.snapshotView(afterScreenUpdates: true)!
            iconSnapshotView.frame = iconFrame
            
            let badgeSnapshotView = cell.badgeLabel.superview!.snapshotView(afterScreenUpdates: true)!
            badgeSnapshotView.frame = badgeFrame
            
            self.itemsContainerView.addSubview(iconSnapshotView)
            self.itemsContainerView.addSubview(badgeSnapshotView)
            self.viewsMovedOutOfVibrancy.append(contentsOf: [iconSnapshotView, badgeSnapshotView])
            
            cell.iconImageView.removeFromSuperview()
            cell.badgeLabel.superview!.removeFromSuperview()
        }
    }
    
    func setupForAnimation() {
        guard self.item.isShareable else { return }
        
        self.iconViewFrame = self.view.convert(self.itemView.iconView.frame, from: self.itemView)
        self.tableView.alpha = 0
        self.viewsMovedOutOfVibrancy.forEach { $0.alpha = 0 }
        self.itemsContainerView.isHidden = true
        self.itemsContainerViewBackground.applyIconMask()
        self.itemsContainerViewBackground.isHidden = false
        self.updateBackgroundViewConstraintsToMatch(frame: self.iconViewFrame)
    }
    
    func setupPosition() {
        guard self.item.isShareable else { return }
        
        if self.verticalPosition == .top {
            self.itemsContainerViewTopConstraint.constant = self.iconViewFrame.minY - (self.tableViewHeightConstraint.constant + 8)
        } else if self.verticalPosition == .bottom {
            self.itemsContainerViewTopConstraint.constant = self.iconViewFrame.maxY + 8
        }
        
        if self.horizontalPosition == .left {
            self.itemsContainerViewLeftConstraint.constant = self.iconViewFrame.minX
        } else if self.horizontalPosition == .right {
            self.itemsContainerViewLeftConstraint.constant = self.iconViewFrame.maxX - self.itemsContainerView.frame.width
        } else if self.horizontalPosition == .center {
            self.itemsContainerViewLeftConstraint.constant = (self.view.frame.width - self.itemsContainerView.frame.width) / 2
        }
        
        self.view.layoutIfNeeded()
    }
    
    func setupBlur() {
        
        let blurEffect = (NSClassFromString("_UICustomBlurEffect") as! UIBlurEffect.Type).init()
        blurEffect.setValue(1, forKeyPath: "scale")
        blurEffect.setValue(0, forKeyPath: "blurRadius")
        self.blurView.effect = blurEffect
        self.blurEffect = blurEffect
        
        self.vibrancyView.effect = UIVibrancyEffect(blurEffect: blurEffect)
        
        // something really changed with vibrancy effects on iOS 11, not sure what
        if #available(iOS 11, *) {
            self.tableVibrancyView.effect = UIVibrancyEffect.widgetPrimary()
        } else {
            self.tableVibrancyView.effect = UIVibrancyEffect(blurEffect: blurEffect)
        }
    }
    
    func updateBackgroundViewConstraintsToMatch(frame: CGRect) {
        
        self.itemsContainerViewBackgroundLeftConstraint.constant = frame.minX
        self.itemsContainerViewBackgroundTopConstraint.constant = frame.minY
        self.itemsContainerViewBackgroundWidthConstraint.constant = frame.width
        self.itemsContainerViewBackgroundHeightConstraint.constant = frame.height
        self.view.layoutIfNeeded()
    }
    
    func updateBackgroundView(withProgress progress: CGFloat) {
        
        let newValue = 30 * progress
        let newRect = CGRect(x: self.iconViewFrame.minX - (newValue / 2),
                             y: self.iconViewFrame.minY - (newValue / 2),
                             width: self.iconViewFrame.width + newValue,
                             height: self.iconViewFrame.height + newValue)
        
        self.updateBackgroundViewConstraintsToMatch(frame: newRect)
        self.itemsContainerViewBackground.applyIconMask()
    }
    
    func updateBackgroundBlur(withProgress progress: CGFloat) {
        
        self.blurEffect.setValue(progress * 15, forKey: "blurRadius")
        self.blurEffect.setValue(1 + (progress * 0.5), forKey: "saturationDeltaFactor")
        self.blurView.effect = self.blurEffect
    }
    
    func animateIn() {
        
        let itemsContainerViewOriginalFrame = self.itemsContainerView.frame
        self.itemsContainerView.transform = CGAffineTransform.transform(rect: itemsContainerViewOriginalFrame, to: self.itemsContainerViewBackground.frame)
        self.itemsContainerView.isHidden = false
        self.itemsContainerViewBackground.layer.mask = nil
        self.itemsContainerViewBackground.layer.cornerRadius = 12
        UIView.animate(withDuration: 0.2, animations: {
            self.updateBackgroundViewConstraintsToMatch(frame: itemsContainerViewOriginalFrame)
            self.itemView.transform = .identity
            self.itemsContainerView.transform = .identity
            self.tableView.alpha = 1
            self.viewsMovedOutOfVibrancy.forEach { $0.alpha = 1 }
        })
    }
    
    func dismiss() {
        
        UIView.animate(withDuration: 0.25, animations: {
            self.blurEffect.setValue(0, forKey: "blurRadius")
            self.blurEffect.setValue(1, forKey: "saturationDeltaFactor")
            self.blurView.effect = self.blurEffect
            
            self.itemView.transform = .identity
            
            guard self.item.isShareable else { return }
            if self.isPresentingOptions {
                self.tableView.alpha = 0
                self.itemsContainerView.transform = CGAffineTransform.transform(rect: self.itemsContainerView.frame, to: self.iconViewFrame)
                self.updateBackgroundViewConstraintsToMatch(frame: self.iconViewFrame)
            } else {
                self.itemsContainerViewBackground.transform = CGAffineTransform.transform(rect: self.itemsContainerViewBackground.frame, to: self.iconViewFrame)
            }
        }, completion: { _ in
            self.delegate?.homeItemActionsViewControllerDidDismiss(self)
        })
    }
    
    @objc func handle3DTouchGesture(_ gestureRecognizer: ThreeDTouchGestureRecognizer) {
        
        if gestureRecognizer.state == .changed {
            self.updateBackgroundBlur(withProgress: gestureRecognizer.pressProgress)
            
            if self.item.isShareable {
                self.updateBackgroundView(withProgress: gestureRecognizer.pressProgress)
            }
            
            if gestureRecognizer.pressProgress >= 0.7 && !self.item.isShareable {
                gestureRecognizer.removeTarget(self, action: nil)
                
                self.notificationFeedbackGenerator.notificationOccurred(.error)
                self.dismiss()
            } else if gestureRecognizer.pressProgress == 1 && self.item.isShareable {
                gestureRecognizer.removeTarget(self, action: nil)
                gestureRecognizer.addTarget(self, action: #selector(handlePanGesture(_:)))
                
                self.impactFeedbackGenerator.impactOccurred()
                self.isPresentingOptions = true
                self.animateIn()
            } else {
                let scale: CGFloat = 1 + (0.06 * gestureRecognizer.pressProgress)
                self.itemView.transform = CGAffineTransform.identity.scaledBy(x: scale, y: scale)
            }
        } else if (gestureRecognizer.state == .ended || gestureRecognizer.state == .cancelled) && !self.isPresentingOptions {
            self.dismiss()
        }
    }
    
    @IBAction func handlePanGesture(_ gestureRecognizer: UIGestureRecognizer) {
        
        if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
            self.selectionFeedbackGenerator.prepare()
            let point = gestureRecognizer.location(in: self.itemsContainerView)
            guard let indexPath = self.tableView.indexPathForRow(at: point), let cell = self.tableView.cellForRow(at: indexPath) as? HomeItemActionCell else { return }
            
            if cell != self.currentSelectedCell {
                self.cellBackgroundView.frame.origin.y = cell.frame.minY
                self.cellBackgroundView.alpha = 0.4
                
                self.view.layoutIfNeeded()
                self.currentSelectedCell = cell
                
                self.selectionFeedbackGenerator.selectionChanged()
                self.selectionFeedbackGenerator.prepare()
            }
        } else if gestureRecognizer.state == .ended || gestureRecognizer.state == .cancelled {
            guard let cell = self.currentSelectedCell, let item = cell.item else { return }
            cell.setHighlighted(false, animated: false)
            self.dismiss()
            self.delegate?.didSelect(itemAction: item, on: self)
        }
    }
    
    @IBAction func dismissTapAction(_ sender: Any) {
        self.dismiss()
    }
}

// MARK: - Table View delegate / data source

extension HomeItemActionsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: self.horizontalPosition == .left ? "HomeItemActionCellLeft" : "HomeItemActionCellRight" , for: indexPath) as! HomeItemActionCell
        cell.item = self.items[indexPath.row]
        return cell
    }
}
