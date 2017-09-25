//
//  SiriSuggestionsWidgetViewController.swift
//  jSpringBoard
//
//  Created by Jota Melo on 24/08/17.
//  Copyright © 2017 jota. All rights reserved.
//

import UIKit

class SiriSuggestionsWidgetViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionViewHeightConstraint: NSLayoutConstraint!
    
    var itemsManager: HomeItemsManager!

    override func viewDidLoad() {
        super.viewDidLoad()

        var cellWidth: CGFloat
        var horizontalInset: CGFloat
        if UIScreen.main.bounds.size.width == 320 {
            cellWidth = 76
            horizontalInset = 0
        } else {
            cellWidth = 79
            horizontalInset = 10
        }
        
        let flowLayout = self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        flowLayout.sectionInset = UIEdgeInsets(top: Settings.shared.dockTopMargin, left: horizontalInset, bottom: 0, right: horizontalInset)
        flowLayout.minimumLineSpacing = 0
        flowLayout.itemSize = CGSize(width: cellWidth, height: 92)
    }
}

// MARK: - Widget Providing

extension SiriSuggestionsWidgetViewController: WidgetProviding {
    
    var name: String {
        return "SIRI APP SUGGESTIONS"
    }
    
    var icon: UIImage {
        return #imageLiteral(resourceName: "siri")
    }
    
    var iconNeedsMasking: Bool {
        return false
    }
    
    func didChange(displayMode: WidgetDisplayMode) {
        
        var bottomCells: [UICollectionViewCell] = []
        for i in 4..<8 {
            let indexPath = IndexPath(item: i, section: 0)
            guard i < self.collectionView.numberOfItems(inSection: 0), let cell = self.collectionView.cellForItem(at: indexPath) else { break }
            bottomCells.append(cell)
        }

        if displayMode == .compact {
            self.collectionViewHeightConstraint.constant = 109.3
            
            UIView.animate(withDuration: 0.3, animations: {
                bottomCells.forEach { $0.alpha = 0 }
            })
        } else {
            self.collectionViewHeightConstraint.constant = 109.3 + 90
            
            bottomCells.forEach { $0.alpha = 0 }
            UIView.animate(withDuration: 0.3, animations: {
                bottomCells.forEach { $0.alpha = 1 }
            })
        }
    }
}

// MARK: - Collection View data source / delegate

extension SiriSuggestionsWidgetViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
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
        
        if !HomeItemsManager.open(app: self.itemsManager.appSuggestions[indexPath.row]) {
            let alert = UIAlertController(title: NSLocalizedString("Oh no", comment: ""), message: NSLocalizedString("You don't have that app", comment: ""), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
}

