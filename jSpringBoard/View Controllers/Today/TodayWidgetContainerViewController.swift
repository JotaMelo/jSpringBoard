//
//  TodayWidgetContainerViewController.swift
//  jSpringBoard
//
//  Created by Jota Melo on 24/08/17.
//  Copyright © 2017 jota. All rights reserved.
//

import UIKit
import NotificationCenter

typealias WidgetViewController = UIViewController & WidgetProviding

enum WidgetDisplayMode {
    case compact
    case expanded
}

protocol WidgetProviding {
    var icon: UIImage { get }
    var iconNeedsMasking: Bool { get }
    var name: String { get }
    
    func didChange(displayMode: WidgetDisplayMode)
}

protocol TodayWidgetContainerViewControllerDelegate: class {
    func displayModeChanged(on viewController: TodayWidgetContainerViewController)
}

class TodayWidgetContainerViewController: UIViewController {

    @IBOutlet weak var widgetVibrancyView: UIVisualEffectView!
    @IBOutlet weak var iconImageView: UIImageView!
    
    @IBOutlet weak var titleLabelVibrancyView: UIVisualEffectView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var maskTitleLabel: UILabel!
    
    @IBOutlet weak var showMoreButtonVibrancyView: UIVisualEffectView!
    @IBOutlet weak var maskShowMoreButton: UIButton!
    
    @IBOutlet weak var showLessButtonVibrancyView: UIVisualEffectView!
    @IBOutlet weak var maskShowLessButton: UIButton!
    
    @IBOutlet var containerView: UIView!
    
    weak var delegate: TodayWidgetContainerViewControllerDelegate?
    var widgetViewController: WidgetViewController!
    private var currentMode: WidgetDisplayMode = .compact
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupHeader()
        self.setupEffects()
        self.setupContent()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.showLessButtonVibrancyView.isHidden = true
        self.widgetViewController.didChange(displayMode: .compact)
    }
    
    func setupHeader() {
        
        self.iconImageView.image = self.widgetViewController.icon
        self.titleLabel.text = self.widgetViewController.name
        self.maskTitleLabel.text = self.widgetViewController.name
        
        if self.widgetViewController.iconNeedsMasking {
            self.iconImageView.applyIconMask()
        }
    }
    
    func setupEffects() {
        
        defer {
            self.maskTitleLabel.isHidden = true
            self.maskShowMoreButton.isHidden = true
            self.maskShowLessButton.isHidden = true
        }
        
        self.widgetVibrancyView.effect = UIVibrancyEffect.widgetPrimary()
        self.titleLabelVibrancyView.effect = UIVibrancyEffect.widgetPrimary()
        self.showMoreButtonVibrancyView.effect = UIVibrancyEffect.widgetPrimary()
        self.showLessButtonVibrancyView.effect = UIVibrancyEffect.widgetPrimary()
        
        guard #available(iOS 11, *) else {
            self.titleLabelVibrancyView.mask = self.maskTitleLabel
            self.showMoreButtonVibrancyView.mask = self.maskShowMoreButton
            self.showLessButtonVibrancyView.mask = self.maskShowLessButton
            return
        }
    }
    
    func setupContent() {
        
        let view = self.widgetViewController.view!
        view.translatesAutoresizingMaskIntoConstraints = false
        self.containerView.addSubview(view)
        
        let topConstraint = view.topAnchor.constraint(equalTo: self.containerView.topAnchor, constant: 0)
        let rightConstraint = view.rightAnchor.constraint(equalTo: self.containerView.rightAnchor, constant: 0)
        let bottomConstraint = view.bottomAnchor.constraint(equalTo: self.containerView.bottomAnchor, constant: 0)
        let leftConstraint = view.leftAnchor.constraint(equalTo: self.containerView.leftAnchor, constant: 0)
        self.containerView.addConstraints([topConstraint, rightConstraint, bottomConstraint, leftConstraint])
    }
    
    @IBAction func toggleShowMore(_ sender: Any) {
        
        if self.currentMode == .compact {
            self.currentMode = .expanded
            self.widgetViewController.didChange(displayMode: .expanded)
            
            self.showMoreButtonVibrancyView.isHidden = true
            self.showLessButtonVibrancyView.isHidden = false
        } else {
            self.currentMode = .compact
            self.widgetViewController.didChange(displayMode: .compact)
            
            self.showMoreButtonVibrancyView.isHidden = false
            self.showLessButtonVibrancyView.isHidden = true
        }
        
        self.delegate?.displayModeChanged(on: self)
    }
}
