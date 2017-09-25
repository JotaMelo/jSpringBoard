//
//  AppGridManager+3DTouch.swift
//  jSpringBoard
//
//  Created by Jota Melo on 05/08/17.
//  Copyright © 2017 jota. All rights reserved.
//

import UIKit

extension AppGridManager: HomeItemActionsViewControllerDelegate {
    
    @objc func handle3DTouchGesture(_ gestureRecognizer: ThreeDTouchGestureRecognizer) {
        guard gestureRecognizer.state == .began, !self.isEditing else { return }
        
        var touchPoint = gestureRecognizer.location(in: self.viewController.view)
        
        // did we hit an icon?
        guard let view = self.viewController.view.hitTest(touchPoint, with: nil), Int(view.frame.size.width) == 60 && Int(view.frame.size.height) == 60 else { return }
        let (collectionView, pageCell) = self.collectionViewAndPageCell(at: touchPoint)
        touchPoint = gestureRecognizer.location(in: collectionView)
        touchPoint.x -= collectionView.contentOffset.x
        
        if let indexPath = pageCell.collectionView.indexPathForItem(at: touchPoint), let cell = pageCell.collectionView.cellForItem(at: indexPath) as? HomeItemCell, let item = cell.item {
            let dragOffset = CGSize(width: cell.center.x - touchPoint.x, height: cell.center.y - touchPoint.y)
            var offsettedTouchPoint = gestureRecognizer.location(in: collectionView)
            offsettedTouchPoint.x += dragOffset.width
            offsettedTouchPoint.y += dragOffset.height
            
            let placeholderView = cell.snapshotView()
            placeholderView.overlayView.isHidden  = true
            placeholderView.badgeOverlayView?.isHidden = true
            placeholderView.nameLabel.isHidden = true
            placeholderView.center = self.viewController.view.convert(offsettedTouchPoint, from: collectionView)
            
            // 1 indexed
            var row: Int
            var column: Int
            
            if collectionView == self.mainCollectionView {
                var appsPerRow: Int
                if self.dockCollectionView == nil {
                    appsPerRow = Settings.shared.appsPerRowOnFolder
                } else {
                    appsPerRow = Settings.shared.appsPerRow
                }
                
                row = Int(ceil(Double(indexPath.row + 1) / Double(appsPerRow)))
                column = indexPath.row - ((row - 1) * appsPerRow) + 1
            } else {
                row = Settings.shared.appRows + 1
                column = indexPath.row + 1
            }
            
            let viewController = self.viewController.storyboard?.instantiateViewController(withIdentifier: "HomeItemActionsViewController") as! HomeItemActionsViewController
            viewController.modalPresentationStyle = .overCurrentContext
            viewController.item = item
            viewController.itemView = placeholderView
            
            if self.dockCollectionView == nil {
                viewController.horizontalPosition = .center
                viewController.verticalPosition = row > 2 ? .top : .bottom
            } else {
                viewController.horizontalPosition = column > Settings.shared.appsPerRow / 2 ? .right : .left
                viewController.verticalPosition = row > Settings.shared.appRows / 2 ? .top : .bottom
            }
            
            viewController.delegate = self
            viewController.viewDidAppearBlock = {
                cell.iconContainerView.isHidden = true
                cell.badgeLabel?.superview?.isHidden = true
                cell.highlightOverlayView?.isHidden = true
                cell.badgeHighlightOverlayView?.isHidden = true
                
                if let cell = cell as? FolderCell {
                    cell.blurView.isHidden = true
                }
            }
            self.threeDTouchRecognizer.addTarget(viewController, action: #selector(handle3DTouchGesture(_:)))
            self.viewController.present(viewController, animated: false, completion: nil)
            
            self.current3DTouchOperation = App3DTouchOperation(viewController: viewController, cell: cell)
        }
    }
    
    func homeItemActionsViewControllerDidDismiss(_ viewController: HomeItemActionsViewController) {
        guard let operation = self.current3DTouchOperation else { return }
        
        operation.cell.iconContainerView.isHidden = false
        operation.cell.highlightOverlayView?.isHidden = false
        operation.cell.badgeHighlightOverlayView?.isHidden = false
        if operation.cell.item?.badge != nil {
            operation.cell.badgeLabel?.superview?.isHidden = false
            operation.cell.badgeLabel?.superview?.alpha = 1
        }
        if let cell = operation.cell as? FolderCell {
            cell.blurView.isHidden = false
        }
        
        operation.viewController.dismiss(animated: false, completion: nil)
        
        self.current3DTouchOperation = nil
    }
    
    func didSelect(itemAction: HomeItemAction, on viewController: HomeItemActionsViewController) {
        guard let operation = self.current3DTouchOperation else { return }
        
        if itemAction.title.hasPrefix("Share ") {
            operation.cell.iconContainerView.isHidden = false
            
            let renderer = UIGraphicsImageRenderer(bounds: operation.cell.iconContainerView.bounds)
            let iconSnapshot = renderer.image { context in
                operation.cell.iconContainerView.layer.render(in: context.cgContext)
            }
            
            operation.cell.iconContainerView.isHidden = true
            
            let activityViewController = UIActivityViewController(activityItems: [iconSnapshot], applicationActivities: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                self.viewController.present(activityViewController, animated: true, completion: nil)
            })
        } else if let cell = operation.cell as? FolderCell, itemAction.title == "Rename" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                self.isEditing = true
                self.showFolder(from: cell, startInRename: true)
                self.isEditing = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                    self.enterEditingMode(suppressHaptic: true)
                })
            })
        } else if let appAction = itemAction as? AppAction {
            if !HomeItemsManager.open(app: appAction.app) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                    let alert = UIAlertController(title: NSLocalizedString("Oh no", comment: ""), message: NSLocalizedString("You don't have that app", comment: ""), preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                    self.viewController.present(alert, animated: true, completion: nil)
                })
            }
        }
    }
}
