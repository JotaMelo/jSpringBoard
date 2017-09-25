//
//  TodayViewController.swift
//  jSpringBoard
//
//  Created by Jota Melo on 20/08/17.
//  Copyright © 2017 jota. All rights reserved.
//

import UIKit
import NotificationCenter

class TodayViewController: UIViewController {

    @IBOutlet var searchBarTopConstraint: NSLayoutConstraint!
    @IBOutlet var spotlightBlurView: UIVisualEffectView!
    @IBOutlet var searchBarBackgroundBlurView: UIVisualEffectView!
    @IBOutlet var searchBarContainerView: UIView!
    @IBOutlet var searchBlurView: UIVisualEffectView!
    @IBOutlet var cancelButtonVibrancyView: UIVisualEffectView!
    @IBOutlet var maskCancelButton: UIButton!
    
    @IBOutlet var dateLabel: UILabel!
    
    @IBOutlet var cancelButtonRightConstraint: NSLayoutConstraint!
    @IBOutlet var searchFieldRightConstraint: NSLayoutConstraint!
    
    @IBOutlet var widgetsStackView: UIStackView!
    
    var widgets: [WidgetViewController] = []
    var searchActionBlock: (() -> Void)?
    
    private var widgetContainers: [TodayWidgetContainerViewController] = []
    private var isAnimatingSearchBarBackgroundBlur = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.searchBarContainerView.addConstraint(self.cancelButtonRightConstraint)
        NSLayoutConstraint.deactivate([self.cancelButtonRightConstraint])
        
        if Settings.shared.isD22 {
            self.searchBarTopConstraint.constant = 48
        }

        let blurEffect = (NSClassFromString("_UICustomBlurEffect") as! UIBlurEffect.Type).init()
        blurEffect.setValue(1, forKeyPath: "scale")
        blurEffect.setValue(15, forKeyPath: "blurRadius")
        self.searchBlurView.effect = blurEffect
        
        self.searchBarBackgroundBlurView.effect = nil
        self.spotlightBlurView.effect = nil
        self.cancelButtonVibrancyView.effect = nil
        
        self.setupWidgets()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE,\ndd MMMM"
        self.dateLabel.text = dateFormatter.string(from: Date())
    }
    
    func setupWidgets() {
        
        for widget in self.widgets {
            let containerViewController = self.storyboard?.instantiateViewController(withIdentifier: "TodayWidgetContainerViewController") as! TodayWidgetContainerViewController
            containerViewController.widgetViewController = widget
            containerViewController.delegate = self
            containerViewController.view.translatesAutoresizingMaskIntoConstraints = false
            self.widgetsStackView.addArrangedSubview(containerViewController.view)
            
            self.widgetContainers.append(containerViewController)
        }
    }
    
    func transitionFromSpotlight() {
        
        NSLayoutConstraint.activate([self.searchFieldRightConstraint])
        NSLayoutConstraint.deactivate([self.cancelButtonRightConstraint])
        
        UIView.animate(withDuration: 0.35, animations: {
            self.spotlightBlurView.effect = nil
            self.view.layoutIfNeeded()
        }, completion: { _ in
            self.spotlightBlurView.isHidden = true
        })
    }
    
    @IBAction func searchAction(_ sender: Any) {
        
        self.searchActionBlock?()
        
        NSLayoutConstraint.deactivate([self.searchFieldRightConstraint])
        NSLayoutConstraint.activate([self.cancelButtonRightConstraint])
        
        self.spotlightBlurView.isHidden = false
        UIView.animate(withDuration: 0.35) {
            self.spotlightBlurView.effect = SpotlightViewController.blurEffect
            self.view.layoutIfNeeded()
        }
    }
}

// MARK: - Scroll View delegateblurEffect

extension TodayViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !self.isAnimatingSearchBarBackgroundBlur else { return }
        
        if scrollView.contentOffset.y >= 15 && self.searchBarBackgroundBlurView.effect == nil {
            self.isAnimatingSearchBarBackgroundBlur = true
            UIView.animate(withDuration: 0.25, animations: {
                self.searchBarBackgroundBlurView.effect = self.searchBlurView.effect
            }, completion: { _ in
                self.isAnimatingSearchBarBackgroundBlur = false
            })
        } else if scrollView.contentOffset.y < 15 && self.searchBarBackgroundBlurView.effect != nil {
            self.isAnimatingSearchBarBackgroundBlur = true
            UIView.animate(withDuration: 0.25, animations: {
                self.searchBarBackgroundBlurView.effect = nil
            }, completion: { _ in
                self.isAnimatingSearchBarBackgroundBlur = false
            })
        }
    }
}

// MARK: - Today Widget Container View Controller delegate

extension TodayViewController: TodayWidgetContainerViewControllerDelegate {
    
    func displayModeChanged(on viewController: TodayWidgetContainerViewController) {
        UIView.animate(withDuration: 0.35) {
            self.view.layoutIfNeeded()
        }
    }
}
