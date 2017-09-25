//
//  HomeViewController.swift
//  jSpringBoard
//
//  Created by Jota Melo on 14/06/17.
//  Copyright © 2017 jota. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController {
    
    @IBOutlet var backgroundView: UIView!
    @IBOutlet var backgroundImageView: UIImageView!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var collectionViewTopConstraint: NSLayoutConstraint!
    @IBOutlet var dockBackgroundBlur: UIVisualEffectView!
    @IBOutlet var dockContainerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var dockCollectionView: UICollectionView!
    @IBOutlet var dockCollectionViewLeftConstraint: NSLayoutConstraint!
    @IBOutlet var pageControl: UIPageControl!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.statusBarStyle ?? .lightContent
    }
    
    var itemsManager: HomeItemsManager!
    var gridManager: AppGridManager!
    var homeButtonManager: VirtualHomeButtonManager!
    var spotlightViewController: SpotlightViewController!
    var todayViewController: TodayViewController!
    
    var spotlightGestureRecognizer: UIPanGestureRecognizer!
    var lastWidth: CGFloat!
    var spotlightOffset: CGFloat!
    var reachabilityPlaceholderView: UIView?
    var readOnlyMode: Bool = false
    var settingsOperation: SettingsOpenOperation?
    var statusBarStyle: UIStatusBarStyle?
    
    override func prefersHomeIndicatorAutoHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.updateWallpaper()
        Settings.shared.wallpaperView = self.backgroundView
        
        if self.itemsManager == nil {
            self.itemsManager = HomeItemsManager()
        }
        
        MaskedIconCache.shared.cacheIcons(for: self.itemsManager.pages.flatMap({ $0 }).filter { $0 is App } as! [App])
        self.gridManager = AppGridManager(viewController: self,
                                          mainCollectionView: self.collectionView,
                                          items: self.itemsManager.pages,
                                          dockCollectionView: self.dockCollectionView,
                                          dockItems: self.itemsManager.dockItems)
        self.gridManager.delegate = self
        
        self.pageControl.numberOfPages = self.gridManager.items.count + 1
        self.pageControl.currentPage = 1
        self.pageControl.pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.4)
        
        self.updateLayout()
        self.setupParallax()
        
        if !self.readOnlyMode {
            self.setupToday()
            self.setupSpotlight()
            
            NotificationCenter.default.addObserver(self, selector: #selector(homeTapped), name: .homeTapped, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(homeDoubleTapped), name: .homeDoubleTapped, object: nil)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateWallpaper), name: .wallpaperUpdated, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.collectionView.contentInset = UIEdgeInsets(top: 0, left: self.view.frame.width, bottom: 0, right: 0)
        
        if self.homeButtonManager == nil && !self.readOnlyMode {
            self.homeButtonManager = VirtualHomeButtonManager(view: UIApplication.shared.keyWindow!)
            
//            let statusBar = UIApplication.shared.value(forKey: "_statusBar") as! UIView
//            self.view.addSubview(statusBar)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if self.lastWidth != self.view.frame.width {
            self.updateLayout()
        }
    }
    
    func updateLayout() {
        
        self.view.layoutIfNeeded()
        
        self.lastWidth = self.view.frame.width
        
        var flowLayout = self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        flowLayout.itemSize = self.collectionView.frame.size
        
        flowLayout = self.dockCollectionView.collectionViewLayout as! UICollectionViewFlowLayout
        flowLayout.itemSize = self.dockCollectionView.frame.size
    }
    
    func setupParallax() {
        
        let motionEffectX = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
        motionEffectX.minimumRelativeValue = 10
        motionEffectX.maximumRelativeValue = -10
        
        let motionEffectY = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
        motionEffectY.minimumRelativeValue = 43
        motionEffectY.maximumRelativeValue = -43
        
        let effectGroup = UIMotionEffectGroup()
        effectGroup.motionEffects = [motionEffectX, motionEffectY]
        self.backgroundImageView.addMotionEffect(effectGroup)
    }
    
    func setupSpotlight() {

        // yeah yeah I shouldn't hardcode these...
        let iconTopMargin = 12 as CGFloat
        let spotlightCollectionViewY = 102 as CGFloat
        let spotlightIconY = spotlightCollectionViewY + Settings.shared.dockTopMargin + iconTopMargin
        let gridIconY = Settings.shared.topMargin + iconTopMargin
        self.spotlightOffset = spotlightIconY - gridIconY
        
        self.spotlightViewController = self.storyboard?.instantiateViewController(withIdentifier: "SpotlightViewController") as! SpotlightViewController
        self.spotlightViewController.itemsManager = self.itemsManager
        self.spotlightViewController.delegate = self
        self.spotlightViewController.view.frame = CGRect(x: 0, y: -self.spotlightOffset, width: self.view.frame.width, height: self.view.frame.height)
        self.spotlightViewController.view.isHidden = true
        self.view.addSubview(self.spotlightViewController.view)
        
        self.spotlightViewController.dismissBlock = {
            UIView.animate(withDuration: 0.35, animations: {
                self.spotlightViewController.view.frame = CGRect(x: 0, y: -self.spotlightOffset, width: self.view.frame.width, height: self.view.frame.height)
                self.collectionViewTopConstraint.constant = 0
                self.view.layoutIfNeeded()
            }, completion: { _ in
                self.spotlightViewController.view.isHidden = true
            })
            self.spotlightGestureRecognizer.isEnabled = true
        }
        
        self.spotlightGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(spotlightHandler(_:)))
        self.spotlightGestureRecognizer.cancelsTouchesInView = true
        self.view.addGestureRecognizer(self.spotlightGestureRecognizer)
    }
    
    func setupToday() {
        
        self.todayViewController = self.storyboard?.instantiateViewController(withIdentifier: "TodayViewController") as! TodayViewController
        self.todayViewController.widgets = self.todayWidgets()
        self.todayViewController.view.frame = CGRect(x: -self.view.frame.width, y: 0, width: self.view.frame.width, height: self.view.frame.height)
        self.collectionView.addSubview(self.todayViewController.view)
        
        self.todayViewController.searchActionBlock = {
            let previousDismissBlock = self.spotlightViewController.dismissBlock
            
            self.spotlightViewController.view.frame = self.view.frame
            self.spotlightViewController.view.transform = CGAffineTransform.identity.scaledBy(x: 1.5, y: 1.5)
            self.spotlightViewController.view.alpha = 0
            self.spotlightViewController.view.isHidden = false
            self.spotlightViewController.searchBarContainerView.isHidden = true
            self.spotlightViewController.blurView.isHidden = true
            
            self.spotlightViewController.dismissBlock = {
                self.spotlightViewController.dismissBlock = nil
                
                self.spotlightViewController.searchBarContainerView.isHidden = true
                self.todayViewController.searchBarContainerView.isHidden = false
                
                self.spotlightViewController.dismiss()
                self.todayViewController.transitionFromSpotlight()
                
                UIView.animate(withDuration: 0.25, animations: {
                    self.spotlightViewController.view.alpha = 0
                    self.spotlightViewController.view.transform = CGAffineTransform.identity.scaledBy(x: 1.5, y: 1.5)
                }, completion: { _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                        self.spotlightViewController.view.removeFromSuperview()
                        self.setupSpotlight()
                    })
                })
                
                self.spotlightViewController.dismissBlock = previousDismissBlock
            }
            
            self.spotlightViewController.animateIn()
            UIView.animate(withDuration: 0.35, animations: {
                self.spotlightViewController.view.alpha = 1
                self.spotlightViewController.view.transform = .identity
            }, completion: { _ in
                self.spotlightViewController.searchBarContainerView.isHidden = false
                self.todayViewController.searchBarContainerView.isHidden = true
            })
        }
    }
    
    func todayWidgets() -> [WidgetViewController] {
        
        var response: [WidgetViewController] = []
        
        let siriWidget = self.storyboard!.instantiateViewController(withIdentifier: "SiriSuggestionsWidgetViewController") as! SiriSuggestionsWidgetViewController
        siriWidget.itemsManager = self.itemsManager
        response.append(siriWidget)
        
        let weatherWidget = self.storyboard!.instantiateViewController(withIdentifier: "WeatherWidgetViewController") as! WeatherWidgetViewController
        response.append(weatherWidget)
        
        return response
    }
    
    func openSettings(iconSnapshot: UIView? = nil) {
        guard let iconSnapshot = iconSnapshot else {
            let settingsNavigationController = self.storyboard!.instantiateViewController(withIdentifier: "SettingsNavigationController") as! UINavigationController
            let settingsViewController = settingsNavigationController.viewControllers.first as! SettingsViewController
            settingsViewController.itemsManager = self.itemsManager
            self.present(settingsNavigationController, animated: true, completion: nil)
            return
        }
        
        let zoomScrollView = UIScrollView(frame: self.collectionView.frame)
        zoomScrollView.contentSize = self.collectionView.frame.size
        zoomScrollView.isScrollEnabled = true
        zoomScrollView.minimumZoomScale = 1
        zoomScrollView.maximumZoomScale = 20
        zoomScrollView.delegate = self
        
        let snapshot = self.collectionView.snapshotView(afterScreenUpdates: true)!
        zoomScrollView.addSubview(snapshot)
        
        self.view.addSubview(zoomScrollView)
        self.collectionView.isHidden = true
        
        let settingsNavigationController = self.storyboard!.instantiateViewController(withIdentifier: "SettingsNavigationController") as! UINavigationController
        settingsNavigationController.view.frame = self.view.frame
        settingsNavigationController.view.clipsToBounds = true
        settingsNavigationController.view.transform = CGAffineTransform.transform(rect: settingsNavigationController.view.frame, to: iconSnapshot.frame)
        settingsNavigationController.view.layer.cornerRadius = 100
        self.view.addSubview(settingsNavigationController.view)
        self.view.addSubview(iconSnapshot)
        
        let settingsViewController = settingsNavigationController.viewControllers.first as! SettingsViewController
        settingsViewController.itemsManager = self.itemsManager
        self.settingsOperation = SettingsOpenOperation(scrollView: zoomScrollView, collectionSnapshotView: snapshot, iconSnapshotView: iconSnapshot, viewControllerTransform: settingsNavigationController.view.transform)
        
        let animationControlPoint1 = CGPoint(x: 0.37, y: 0.13)
        let animationControlPoint2 = CGPoint(x: 0, y: 1)
        let animationDuration = 0.5 as TimeInterval
        
        UIView.animate(withDuration: animationDuration - 0.2, delay: animationDuration / 2, options: [], animations: {
            zoomScrollView.alpha = 0
        }, completion: nil)
    
        UIViewPropertyAnimator(duration: animationDuration, controlPoint1: animationControlPoint1, controlPoint2: animationControlPoint2) {
            var newFrame = iconSnapshot.frame
            newFrame.origin.x -= 40
            newFrame.origin.y -= 40
            newFrame.size.height += 40
            newFrame.size.width += 40
            zoomScrollView.zoom(to: newFrame, animated: false)
        }.startAnimation()
        
        self.statusBarStyle = .default
        let animation = UIViewPropertyAnimator(duration: animationDuration, controlPoint1: animationControlPoint1, controlPoint2: animationControlPoint2) {
            self.setNeedsStatusBarAppearanceUpdate()
            settingsNavigationController.view.transform = .identity
            iconSnapshot.transform = CGAffineTransform.transform(rect: iconSnapshot.frame, to: self.view.frame)
        }
        animation.addCompletion { _ in
            self.present(settingsNavigationController, animated: false, completion: nil)
        }
        animation.startAnimation()
        
        let cornerRadiusAnimation = CABasicAnimation(keyPath: "cornerRadius")
        cornerRadiusAnimation.fromValue = 100
        cornerRadiusAnimation.toValue = 0
        cornerRadiusAnimation.duration = animationDuration - 0.2
        cornerRadiusAnimation.fillMode = kCAFillModeForwards
        cornerRadiusAnimation.isRemovedOnCompletion = false
        settingsNavigationController.view.layer.add(cornerRadiusAnimation, forKey: nil)
    
        UIView.animate(withDuration: 0.15, animations: {
            iconSnapshot.alpha = 0
        })
    }
    
    func refreshGridManager() {
        
        self.gridManager.delegate = nil
        self.gridManager.items = self.itemsManager.pages
        self.gridManager.dockItems = self.itemsManager.dockItems
        self.gridManager.delegate = self
        
        self.collectionView.reloadData()
        self.dockCollectionView.reloadData()
    }
    
    func closeSettings() {
        guard let operation = self.settingsOperation, let modalViewController = self.presentedViewController else { return }
        
        self.refreshGridManager()
        let modalSnapshot = modalViewController.view.snapshotView(afterScreenUpdates: true)!
        modalSnapshot.frame = modalViewController.view.frame
        modalViewController.view.window?.addSubview(modalSnapshot)
        modalSnapshot.applyIconMask()
        
        operation.iconSnapshotView.alpha = 0
        modalViewController.view.window?.addSubview(operation.iconSnapshotView)
        modalViewController.dismiss(animated: false, completion: {
            self.statusBarStyle = .lightContent
            let animation = UIViewPropertyAnimator(duration: 0.4, controlPoint1: CGPoint(x: 0.37, y: 0.13), controlPoint2: CGPoint(x: 0, y: 1)) {
                operation.scrollView.setZoomScale(1, animated: false)
                operation.scrollView.alpha = 1
                
                self.setNeedsStatusBarAppearanceUpdate()
                
                modalSnapshot.transform = operation.viewControllerTransform
                operation.iconSnapshotView.transform = .identity
                operation.iconSnapshotView.alpha = 1
            }
            animation.addCompletion { _ in
                self.collectionView.isHidden = false
                modalSnapshot.removeFromSuperview()
                operation.scrollView.removeFromSuperview()
                operation.iconSnapshotView.removeFromSuperview()
                self.settingsOperation = nil
            }
            animation.startAnimation()
        })
    }
    
    @objc func spotlightHandler(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard self.collectionView.contentOffset.x >= 0 else { return }
        
        let translation = gestureRecognizer.translation(in: self.view)
        var progress = translation.y / self.spotlightOffset
        if progress > 1 {
            progress = 1
        } else if progress < 0 {
            progress = 0
        }
        
        if gestureRecognizer.state == .began {
            self.spotlightViewController.setupAnimation(out: false)
            self.spotlightViewController.view.isHidden = false
        } else if gestureRecognizer.state == .changed {
            self.spotlightViewController.updateAnimationProgress(progress)
            self.collectionViewTopConstraint.constant = self.spotlightOffset * progress
            self.spotlightViewController.view.frame = CGRect(x: 0, y: -(self.spotlightOffset * (1 - progress)), width: self.view.frame.width, height: self.view.frame.height)
            self.view.layoutIfNeeded()
        } else {
            if progress < 0.5 {
                self.spotlightViewController.animateOut()
                UIView.animate(withDuration: 0.35, animations: {
                    self.spotlightViewController.view.frame = CGRect(x: 0, y: -self.spotlightOffset, width: self.view.frame.width, height: self.view.frame.height)
                    self.collectionViewTopConstraint.constant = 0
                    self.view.layoutIfNeeded()
                }, completion: { _ in
                    self.spotlightViewController.view.isHidden = true
                })
            } else {
                self.spotlightViewController.animateIn()
                UIView.animate(withDuration: 0.35, animations: {
                    self.spotlightViewController.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
                    self.collectionViewTopConstraint.constant = self.spotlightOffset
                    self.view.layoutIfNeeded()
                })
                gestureRecognizer.isEnabled = false
            }
        }
    }
    
    @objc func toggleRechability() {
        
        let newValue: CGFloat
        if self.collectionViewTopConstraint.constant == 0 {
            newValue = (self.view.frame.height / 2) - Settings.shared.topMargin
            
            let placeholderView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: newValue))
            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(toggleRechability))
            placeholderView.addGestureRecognizer(tapRecognizer)
            self.view.addSubview(placeholderView)
            
            self.reachabilityPlaceholderView = placeholderView
        } else {
            newValue = 0
            self.reachabilityPlaceholderView?.removeFromSuperview()
        }
        
        let animation = UIViewPropertyAnimator(duration: 0.35, controlPoint1: CGPoint(x: 0.25, y: 0.10), controlPoint2: CGPoint(x: 0.54, y: 0.89)) {
            self.collectionViewTopConstraint.constant = newValue
            self.view.layoutIfNeeded()
        }
        animation.startAnimation()
    }
    
    @objc func homeTapped() {
        
        if self.settingsOperation != nil {
            self.closeSettings()
        } else if let navigationController = self.presentedViewController as? UINavigationController, navigationController.viewControllers.first is SettingsViewController {
            self.refreshGridManager()
            self.dismiss(animated: true, completion: nil)
        } else if self.presentedViewController == nil && self.collectionViewTopConstraint.constant != 0 {
            if self.spotlightViewController.view.isHidden {
                self.toggleRechability()
            } else {
                self.spotlightViewController.dismiss()
            }
        } else {
            self.gridManager.homeAction()
        }
    }
    
    @objc func homeDoubleTapped() {
        guard self.presentedViewController == nil, self.spotlightViewController.view.isHidden else { return }
        self.toggleRechability()
    }
    
    @objc func updateWallpaper() {
        self.backgroundImageView.contentMode = Settings.shared.isOriginalWallpaper ? .center : .scaleAspectFill
        self.backgroundImageView.image = Settings.shared.wallpaper
    }
}

// MARK: - App Grid Manager delegate

extension HomeViewController: AppGridManagerDelegate {
    
    func didUpdateItems(on manager: AppGridManager) {
        
        self.itemsManager.pages = manager.items
        self.itemsManager.dockItems = manager.dockItems
        
        DispatchQueue.global(qos: .utility).async {
            self.itemsManager.persistToDisk()
        }
    }
    
    func didUpdate(pageCount: Int, on manager: AppGridManager) {
        self.pageControl.numberOfPages = pageCount + 1
    }
    
    func didMove(toPage page: Int, on manager: AppGridManager) {
        self.pageControl.currentPage = page + 1
    }
    
    func collectionViewDidScroll(_ collectionView: UICollectionView, on manager: AppGridManager) {
        
        if collectionView.contentOffset.x < 0 {
            self.dockCollectionViewLeftConstraint.constant = fabs(collectionView.contentOffset.x)
            self.view.layoutIfNeeded()
            
            let progress = fabs(collectionView.contentOffset.x) / (self.view.frame.width / 2)
            self.dockBackgroundBlur.alpha = 1 - progress
            self.pageControl.alpha = self.dockBackgroundBlur.alpha
        } else if collectionView.contentOffset.x >= 0 {
            if self.dockBackgroundBlur.alpha != 1 {
                self.dockBackgroundBlur.alpha = 1
            }
            
            if self.pageControl.alpha != 1 {
                self.pageControl.alpha = 1
            }
            
            if self.dockCollectionViewLeftConstraint.constant != 0 {
                self.dockCollectionViewLeftConstraint.constant = 0
                self.view.layoutIfNeeded()
            }
        }
    }
    
    func didSelect(app: App, on manager: AppGridManager) {
        
        if !HomeItemsManager.open(app: app) {
            let alert = UIAlertController(title: NSLocalizedString("Oh no", comment: ""), message: NSLocalizedString("You don't have that app", comment: ""), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func openSettings(fromSnapshotView snapshotView: UIView, on manager: AppGridManager) {
        self.openSettings(iconSnapshot: snapshotView)
    }
    
    func didEnterEditingMode(on manager: AppGridManager) { }
    func didBeginFolderDragOut(transfer: AppDragOperationTransfer, on manager: AppGridManager) { }
    func didDelete(item: HomeItem, on manager: AppGridManager) { }
}

// MARK: - Scroll View delegate

extension HomeViewController: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        
        if let operation = self.settingsOperation, operation.scrollView == scrollView {
            return operation.collectionSnapshotView
        }
        return nil
    }
}

// MARK: - Spotlight View Controller delegate

extension HomeViewController: SpotlightViewControllerDelegate {
    
    func didSelect(app: App, on viewController: SpotlightViewController) {
        
        if app.bundleID == "com.apple.Preferences" {
            self.openSettings()
        } else {
            self.didSelect(app: app, on: self.gridManager)
        }
    }
}
