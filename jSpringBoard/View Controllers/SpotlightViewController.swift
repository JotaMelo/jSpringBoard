//
//  SpotlightViewController.swift
//  jSpringBoard
//
//  Created by Jota Melo on 13/08/17.
//  Copyright © 2017 jota. All rights reserved.
//

import UIKit

protocol SpotlightViewControllerDelegate: class {
    func didSelect(app: App, on viewController: SpotlightViewController)
}

class SpotlightViewController: UIViewController {
    
    static var blurEffect: UIBlurEffect {
        let blurEffect = (NSClassFromString("_UICustomBlurEffect") as! UIBlurEffect.Type).init(style: .dark)
        blurEffect.setValue(1, forKeyPath: "scale")
        blurEffect.setValue(15, forKeyPath: "blurRadius")
        blurEffect.setValue(1.5, forKey: "saturationDeltaFactor")
        return blurEffect
    }

    @IBOutlet var blurView: UIVisualEffectView!
    @IBOutlet var blurOverlayView: UIView!
    
    @IBOutlet var searchBarTopConstraint: NSLayoutConstraint!
    @IBOutlet var searchBarContainerView: UIView!
    @IBOutlet var cancelButtonVibrancyView: UIVisualEffectView!
    @IBOutlet var maskCancelButton: UIButton!

    @IBOutlet var appSuggestionsLabelVibrancyView: UIVisualEffectView!
    @IBOutlet var maskAppSuggestionsLabel: UILabel!
    
    @IBOutlet var showMoreButtonVibrancyView: UIVisualEffectView!
    @IBOutlet var maskShowMoreButton: UIButton!
    
    @IBOutlet var showLessButtonVibrancyView: UIVisualEffectView!
    @IBOutlet var maskShowLessButton: UIButton!
    
    @IBOutlet var applicationsLabelVibrancyView: UIVisualEffectView!
    @IBOutlet var maskApplicationsLabel: UILabel!
    
    @IBOutlet var searchTextField: UITextField!
    @IBOutlet var microphoneButton: UIButton!
    @IBOutlet var clearButton: UIButton!
    
    @IBOutlet var vibrancyViews: [UIVisualEffectView]!
    
    @IBOutlet var suggestionsContainerView: UIView!
    @IBOutlet var suggestionsContainerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var collectionView: UICollectionView!
    
    @IBOutlet var searchContainerView: UIView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var tableViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet var speakNowContainerView: UIView!
    
    weak var delegate: SpotlightViewControllerDelegate?
    var itemsManager: HomeItemsManager!
    var dismissBlock: (() -> Void)?
    var todayMode = false
    
    private var searchResults: [SearchResult] = []
    private var animation: UIViewPropertyAnimator!
    
    deinit {
        self.animation?.stopAnimation(true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupVibrancyViews()
        
        if Settings.shared.isD22 {
            self.searchBarTopConstraint.constant = 48
        }
        
        self.searchTextField.attributedPlaceholder = NSAttributedString(string: NSLocalizedString("Search", comment: ""), attributes: [NSAttributedStringKey.font: self.searchTextField.font!, NSAttributedStringKey.foregroundColor: #colorLiteral(red: 0.3490196078, green: 0.6117647059, blue: 0.6117647059, alpha: 1)])
        self.searchTextField.addTarget(self, action: #selector(searchFieldChanged), for: .editingChanged)
        
        let flowLayout = self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        flowLayout.sectionInset = UIEdgeInsets(top: Settings.shared.dockTopMargin, left: Settings.shared.horizontalMargin - 8, bottom: 0, right: Settings.shared.horizontalMargin - 8)
        flowLayout.minimumLineSpacing = 11
        flowLayout.itemSize = Settings.shared.cellSize
        
        self.tableView.contentInset = UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0)
        
        self.blurView.effect = nil
        self.setupAnimation(out: false)
        self.animation.fractionComplete = 0
    }
    
    func setupVibrancyViews() {
        
        defer {
            self.maskCancelButton.isHidden = true
            self.maskAppSuggestionsLabel.isHidden = true
            self.maskShowMoreButton.isHidden = true
            self.maskShowLessButton.isHidden = true
            self.maskApplicationsLabel.isHidden = true
        }
        
        let vibrancyEffect = UIVibrancyEffect(blurEffect: UIBlurEffect(style: .dark))
        self.vibrancyViews.forEach { $0.effect = vibrancyEffect }
        
        guard #available(iOS 11, *) else {
            self.cancelButtonVibrancyView.mask = self.maskCancelButton
            self.appSuggestionsLabelVibrancyView.mask = self.maskAppSuggestionsLabel
            self.showMoreButtonVibrancyView.mask = self.maskShowMoreButton
            self.showLessButtonVibrancyView.mask = self.maskShowLessButton
            self.applicationsLabelVibrancyView.mask = self.maskApplicationsLabel
            return
        }
    }
    
    func updateAnimationProgress(_ progress: CGFloat) {
        self.animation.fractionComplete = progress
    }
    
    func setupAnimation(out: Bool) {
        
        self.animation?.stopAnimation(true)
        
        let hideBlur = out || self.todayMode
        self.blurView.effect = hideBlur ? SpotlightViewController.blurEffect : nil
        self.animation = UIViewPropertyAnimator(duration: 0.35, curve: .easeIn) {
            self.blurView.effect = hideBlur ? nil : SpotlightViewController.blurEffect
            
            self.suggestionsContainerView.alpha = out ? 0 : 1
            self.searchContainerView.alpha = out ? 0 : 1
        }
        self.animation.isUserInteractionEnabled = true
        self.animation.startAnimation()
        self.animation.pauseAnimation()
    }
    
    func animateOut(reversed: Bool = true) {
        
        self.searchTextField.resignFirstResponder()
        self.animation.isReversed = reversed
        self.animation.addCompletion { _ in
            self.suggestionsContainerView.isHidden = false
            self.searchContainerView.isHidden = true
            self.searchTextField.text = ""
        }
        self.animation.startAnimation()
    }
    
    func animateIn() {
        
        self.animation.isReversed = false
        self.animation.addCompletion { _ in
            self.searchTextField.becomeFirstResponder()
        }
        self.animation.startAnimation()
    }
    
    @objc func searchFieldChanged() {
        
        self.microphoneButton.isHidden = self.searchTextField.hasText
        self.clearButton.isHidden = !self.searchTextField.hasText
        
        if let text = self.searchTextField.text, text.characters.count > 0 {
            self.searchResults = self.itemsManager.search(text)
            if self.searchResults.count > 0 {
                self.searchContainerView.isHidden = false
                self.tableViewHeightConstraint.constant = (self.tableView.rowHeight * CGFloat(self.searchResults.count)) + 8
                self.view.layoutIfNeeded()
                self.tableView.reloadData()
            } else {
                self.searchContainerView.isHidden = true
            }
            
            self.suggestionsContainerView.isHidden = true
        } else {
            self.suggestionsContainerView.isHidden = false
            self.searchContainerView.isHidden = true
            
            self.searchResults = []
            self.tableView.reloadData()
        }
    }
    
    @IBAction func toggleShowMore(_ sender: Any) {
        
        var bottomCells: [UICollectionViewCell] = []
        for i in 4..<8 {
            let indexPath = IndexPath(item: i, section: 0)
            guard i < self.collectionView.numberOfItems(inSection: 0), let cell = self.collectionView.cellForItem(at: indexPath) else { break }
            bottomCells.append(cell)
        }
        
        if self.suggestionsContainerViewHeightConstraint.constant == 107 {
            self.showMoreButtonVibrancyView.isHidden = true
            self.showLessButtonVibrancyView.isHidden = false
            
            bottomCells.forEach { $0.alpha = 0 }
            UIView.animate(withDuration: 0.25, animations: {
                bottomCells.forEach { $0.alpha = 1 }
                self.suggestionsContainerViewHeightConstraint.constant = 207
                self.view.layoutIfNeeded()
            })
        } else {
            self.showMoreButtonVibrancyView.isHidden = false
            self.showLessButtonVibrancyView.isHidden = true
            
            UIView.animate(withDuration: 0.25, animations: {
                bottomCells.forEach { $0.alpha = 0 }
                self.suggestionsContainerViewHeightConstraint.constant = 107
                self.view.layoutIfNeeded()
            })
        }
    }
    
    @IBAction func startDictation(_ sender: Any) {
        
        SpeechRecognizer.shared.authorize {
            self.searchTextField.resignFirstResponder()
            UIView.animate(withDuration: 0.25) {
                self.speakNowContainerView.transform = .identity
                self.speakNowContainerView.alpha = 1
            }
            
            SpeechRecognizer.shared.startRecognition { text in
                self.searchTextField.text = text
                self.searchFieldChanged()
                self.stopDictation(nil)
            }
        }
    }
    
    @IBAction func stopDictation(_ sender: Any?) {
        
        SpeechRecognizer.shared.stopRecognition()
        UIView.animate(withDuration: 0.25) {
            self.speakNowContainerView.transform = CGAffineTransform.identity.scaledBy(x: 0.7, y: 0.7)
            self.speakNowContainerView.alpha = 0
        }
    }
    
    @IBAction func clearText(_ sender: Any) {
        
        self.searchTextField.text = ""
        self.searchTextField.becomeFirstResponder()
        self.searchFieldChanged()
    }
    
    @IBAction func dismiss(_ sender: Any? = nil) {
        
        self.setupAnimation(out: true)
        self.animateOut(reversed: false)
        self.dismissBlock?()
    }
}

// MARK: - Text Field delegate

extension SpotlightViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - Collection View data source / delegate

extension SpotlightViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.itemsManager.appSuggestions.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let app = self.itemsManager.appSuggestions[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AppCell", for: indexPath) as! HomeItemCell
        
        cell.item = app
        cell.badgeLabel?.superview?.isHidden = true
        cell.createBadgeOverlayView()
        cell.badgeHighlightOverlayView?.isHidden = true
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.dismiss()
        self.delegate?.didSelect(app: self.itemsManager.appSuggestions[indexPath.row], on: self)
    }
}

// MARK: - Table View data source / delegate

extension SpotlightViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultCell", for: indexPath) as! SearchResultCell
        cell.setup(withResult: self.searchResults[indexPath.row], hideSeparator: indexPath.row == tableView.numberOfRows(inSection: 0) - 1)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.dismiss()
        self.delegate?.didSelect(app: self.searchResults[indexPath.row].app, on: self)
    }
}
