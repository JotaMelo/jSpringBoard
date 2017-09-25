//
//  AppGridManager+DragOperations.swift
//  jSpringBoard
//
//  Created by Jota Melo on 05/08/17.
//  Copyright © 2017 jota. All rights reserved.
//

import UIKit

extension AppGridManager {
    
    @objc func handleLongGesture(_ gestureRecognizer: UILongPressGestureRecognizer) {
        
        switch gestureRecognizer.state {
        case .began:
            self.beginDragOperation(gestureRecognizer)
        case .changed:
            self.updateDragOperation(gestureRecognizer)
        default:
            self.endDragOperation(gestureRecognizer)
        }
    }
    
    func beginDragOperation(_ gestureRecognizer: UILongPressGestureRecognizer) {
        
        self.feedbackGenerator.prepare()
        var touchPoint = gestureRecognizer.location(in: self.viewController.view)
        
        // did we hit an icon?
        guard let view = self.viewController.view.hitTest(touchPoint, with: nil), Int(view.frame.size.width) == 60 && Int(view.frame.size.height) == 60 else { return }
        let (collectionView, pageCell) = self.collectionViewAndPageCell(at: touchPoint)
        touchPoint = gestureRecognizer.location(in: collectionView)
        touchPoint.x -= collectionView.contentOffset.x
        
        if let indexPath = pageCell.collectionView.indexPathForItem(at: touchPoint), let cell = pageCell.collectionView.cellForItem(at: indexPath) as? HomeItemCell, let item = cell.item {
            // independently of where the user touched, we want to consider that to be the center of the cell
            // this offset will always be applied in the .changed state to get the new position for the placeholder view
            let dragOffset = CGSize(width: cell.center.x - touchPoint.x, height: cell.center.y - touchPoint.y)
            var offsettedTouchPoint = gestureRecognizer.location(in: collectionView)
            offsettedTouchPoint.x += dragOffset.width
            offsettedTouchPoint.y += dragOffset.height
            
            let placeholderView = cell.snapshotView()
            placeholderView.center = self.viewController.view.convert(offsettedTouchPoint, from: collectionView)
            self.viewController.view.addSubview(placeholderView)
            cell.contentView.isHidden = true
            
            self.enterEditingMode()
            self.currentDragOperation = AppDragOperation(placeholderView: placeholderView, dragOffset: dragOffset, item: item, originalPageCell: pageCell, originalIndexPath: indexPath)
            
            UIView.animate(withDuration: 0.25, animations: {
                placeholderView.transform = CGAffineTransform.identity.scaledBy(x: 1.3, y: 1.3)
                placeholderView.alpha = 0.8
                placeholderView.deleteButtonContainer?.transform = .identity
            })
        }
    }
    
    func updateDragOperation(_ gestureRecognizer: UILongPressGestureRecognizer) {
        
        var touchPoint = gestureRecognizer.location(in: self.viewController.view)
        guard let currentOperation = self.currentDragOperation else { return }
        
        let (collectionView, pageCell) = self.collectionViewAndPageCell(at: touchPoint)
        touchPoint = gestureRecognizer.location(in: collectionView)
        
        let convertedTouchPoint = self.viewController.view.convert(touchPoint, from: collectionView)
        currentOperation.movePlaceholder(to: convertedTouchPoint)
        
        if currentOperation.needsUpdate {
            return
        }
        
        touchPoint.x -= collectionView.contentOffset.x
        
        if self.dockCollectionView == nil {
            var shouldStartDragOutTimer = false
            
            if touchPoint.y < self.mainCollectionView.frame.minY && !self.ignoreDragOutOnTop {
                shouldStartDragOutTimer = true
            } else if touchPoint.y > self.mainCollectionView.frame.maxY && !self.ignoreDragOutOnBottom {
                shouldStartDragOutTimer = true
            }
            
            if shouldStartDragOutTimer {
                if self.folderRemovalTimer != nil {
                    return
                }
                
                self.folderRemovalTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(folderRemoveTimerHandler), userInfo: nil, repeats: false)
                return
            }
        }
        
        self.folderRemovalTimer?.invalidate()
        self.folderRemovalTimer = nil
        
        var destinationIndexPath: IndexPath
        let flowLayout = pageCell.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        let appsPerRow = self.dockCollectionView == nil ? Settings.shared.appRowsOnFolder : Settings.shared.appsPerRow
        var isEdgeCell = false
        
        if let indexPath = pageCell.collectionView.indexPathForItem(at: touchPoint), pageCell == currentOperation.currentPageCell {
            guard let itemCell = pageCell.collectionView.cellForItem(at: indexPath) as? HomeItemCell else { return }
            
            let iconCenter = itemCell.iconContainerView.center
            let offset = 20 as CGFloat
            let targetRect = CGRect(x: iconCenter.x - offset, y: iconCenter.y - offset, width: offset * 2, height: offset * 2)
            
            let convertedPoint = itemCell.convert(touchPoint, from: pageCell.collectionView)
            if targetRect.contains(convertedPoint) && indexPath.row != currentOperation.currentIndexPath.row && collectionView == self.mainCollectionView {
                if self.currentFolderOperation != nil || currentOperation.item is Folder || self.dockCollectionView == nil {
                    return
                }
                
                self.pageTimer?.invalidate()
                self.startFolderOperation(for: itemCell)
                return
            } else if convertedPoint.x < itemCell.iconContainerView.frame.minX {
                destinationIndexPath = indexPath
            } else if convertedPoint.x > itemCell.iconContainerView.frame.maxX {
                if (indexPath.row + 1) % appsPerRow == 0 {
                    destinationIndexPath = indexPath
                    isEdgeCell = true
                } else {
                    destinationIndexPath = IndexPath(item: indexPath.row + 1, section: 0)
                }
            } else {
                self.cancelFolderOperation()
                return
            }
        } else if touchPoint.x <= flowLayout.sectionInset.left {
            self.cancelFolderOperation()
            
            if collectionView != self.mainCollectionView {
                destinationIndexPath = IndexPath(item: 0, section: 0)
            } else if !(self.pageTimer?.isValid ?? false) && collectionView == self.mainCollectionView {
                self.pageTimer = Timer.scheduledTimer(timeInterval: 0.7, target: self, selector: #selector(pageTimerHandler), userInfo: -1, repeats: false)
                return
            } else {
                return
            }
        } else if touchPoint.x > collectionView.frame.size.width - flowLayout.sectionInset.right {
            self.cancelFolderOperation()
            
            if collectionView != self.mainCollectionView {
                if self.dockItems.count == 0 {
                    destinationIndexPath = IndexPath(item: 0, section: 0)
                } else {
                    destinationIndexPath = IndexPath(item: self.dockItems.count - 1, section: 0)
                }
            } else if !(self.pageTimer?.isValid ?? false) && collectionView == self.mainCollectionView {
                self.pageTimer = Timer.scheduledTimer(timeInterval: 0.7, target: self, selector: #selector(pageTimerHandler), userInfo: 1, repeats: false)
                return
            } else {
                return
            }
        } else {
            touchPoint.x += 15 // maximum spacing between cells
            
            if let indexPath = pageCell.collectionView.indexPathForItem(at: touchPoint) {
                destinationIndexPath = indexPath
            } else if let dockCollectionView = self.dockCollectionView, collectionView == self.mainCollectionView && dockCollectionView.visibleCells.contains(currentOperation.currentPageCell) {
                if self.items[self.currentPage].count < Settings.shared.appsPerPage {
                    destinationIndexPath = IndexPath(item: self.items[self.currentPage].count + 1, section: 0)
                } else {
                    return
                }
            } else {
                self.cancelFolderOperation()
                self.pageTimer?.invalidate()
                return
            }
        }
        
        self.ignoreDragOutOnTop = false
        self.ignoreDragOutOnBottom = false
        
        self.cancelFolderOperation()
        
        self.pageTimer?.invalidate()
        self.pageTimer = nil
        
        self.folderTimer?.invalidate()
        self.folderTimer = nil
        
        if destinationIndexPath.row % appsPerRow == 0 {
            isEdgeCell = true
        }
        
        // The behavior for dragging on the same line is different:
        // the dragged app takes the place of the app on its left
        // On other lines it takes the place of the app on its right
        let destinationLine = destinationIndexPath.row / appsPerRow
        let originalLine = currentOperation.originalIndexPath.row / appsPerRow
        if destinationLine == originalLine && currentOperation.currentPageCell == currentOperation.originalPageCell && !isEdgeCell {
            destinationIndexPath = IndexPath(item: destinationIndexPath.row - 1, section: 0)
        }
        
        if destinationIndexPath.row >= pageCell.collectionView.numberOfItems(inSection: 0) && destinationIndexPath.row > 0 {
            destinationIndexPath = IndexPath(item: destinationIndexPath.row - 1, section: 0)
        } else if destinationIndexPath.row == -1 {
            destinationIndexPath = IndexPath(item: 0, section: 0)
        }
        
        if destinationIndexPath.row != currentOperation.currentIndexPath.row {
            if let dockCollectionView = self.dockCollectionView {
                if collectionView == dockCollectionView && !dockCollectionView.visibleCells.contains(currentOperation.currentPageCell) {
                    self.moveToDock(operation: currentOperation, pageCell: pageCell, destinationIndexPath: destinationIndexPath)
                    return
                } else if collectionView == self.mainCollectionView && dockCollectionView.visibleCells.contains(currentOperation.currentPageCell) { //&& currentOperation.originalPageCell == currentOperation.currentPageCell {
                    self.moveFromDock(operation: currentOperation, pageCell: pageCell, destinationIndexPath: destinationIndexPath)
                    return
                }
            }
            
            let numberOfItems = pageCell.collectionView.numberOfItems(inSection: 0)
            if currentOperation.currentIndexPath.row < numberOfItems && destinationIndexPath.row < numberOfItems {
                pageCell.collectionView.moveItem(at: currentOperation.currentIndexPath, to: destinationIndexPath)
                currentOperation.currentIndexPath = destinationIndexPath
            }
        }
    }
    
    func endDragOperation(_ gestureRecognizer: UILongPressGestureRecognizer) {
        
        if self.currentFolderOperation != nil {
            self.folderTimer?.invalidate()
            self.folderTimer = nil
            
            self.commitFolderOperation(didDrop: true)
            return
        }
        
        guard let currentOperation = self.currentDragOperation,
            let cell = currentOperation.currentPageCell.collectionView.cellForItem(at: currentOperation.currentIndexPath) as? HomeItemCell
            else { return }
        
        self.updateState(forPageCell: currentOperation.currentPageCell)
        let convertedRect = currentOperation.currentPageCell.collectionView.convert(cell.frame, to: self.viewController.view)
        
        // fixing possible inconsistencies
        var visiblePageCells = [self.currentPageCell]
        if let dockCollectionView = self.dockCollectionView, let pageCell = dockCollectionView.visibleCells[0] as? PageCell {
            visiblePageCells.append(pageCell)
        }
        for cell in visiblePageCells.reduce([], { $0 + $1.collectionView.visibleCells }) {
            let cell = cell as! HomeItemCell
            cell.nameLabel?.alpha = 1
            cell.animate(force: true)
        }
        
        UIView.animate(withDuration: 0.25, animations: {
            currentOperation.placeholderView.transform = .identity
            currentOperation.placeholderView.frame = convertedRect
        }, completion: { _ in
            cell.contentView.isHidden = false
            currentOperation.placeholderView.removeFromSuperview()
            self.currentDragOperation = nil
        })
    }
    
    func moveToDock(operation: AppDragOperation, pageCell: PageCell, destinationIndexPath: IndexPath) {
        
        if self.dockItems.count >= Settings.shared.appsPerRow {
            return
        }
        
        if operation.item is Folder {
            return
        }
        
        self.dockItems.insert(operation.item, at: destinationIndexPath.row)
        
        var didRestoreSavedState = false
        if let savedState = operation.savedState {
            self.items = savedState
            operation.savedState = nil
            didRestoreSavedState = true
        } else {
            self.items[self.currentPage].remove(at: operation.currentIndexPath.row)
        }
        
        pageCell.items = self.dockItems
        pageCell.draggedItem = operation.item
        pageCell.collectionView.performBatchUpdates({
            pageCell.collectionView.insertItems(at: [destinationIndexPath])
        }, completion: nil)
        pageCell.updateSectionInset()
        
        let currentPageCell = operation.currentPageCell
        currentPageCell.items = self.items[self.currentPage]
        currentPageCell.collectionView.performBatchUpdates({
            currentPageCell.collectionView.deleteItems(at: [operation.currentIndexPath])
            
            if didRestoreSavedState {
                let indexPath = IndexPath(item: (Settings.shared.appsPerPage) - 1, section: 0)
                currentPageCell.collectionView.insertItems(at: [indexPath])
            }
        }, completion: nil)
        
        operation.currentPageCell = pageCell
        operation.currentIndexPath = destinationIndexPath
    }
    
    func moveFromDock(operation: AppDragOperation, pageCell: PageCell, destinationIndexPath: IndexPath) {
        
        var didMoveLastItem = false
        if self.items[self.currentPage].count == Settings.shared.appsPerPage {
            didMoveLastItem = true
            operation.savedState = self.items
            self.moveLastItem(inPage: self.currentPage)
            
            var indexPathsToReload: [IndexPath] = []
            for i in 0..<self.items.count {
                guard i != self.currentPage else { continue }
                let indexPath = IndexPath(item: i, section: 0)
                indexPathsToReload.append(indexPath)
            }
            self.mainCollectionView.reloadItems(at: indexPathsToReload)
        }
        
        self.items[self.currentPage].insert(operation.item, at: destinationIndexPath.row)
        self.dockItems.remove(at: operation.currentIndexPath.row)
        
        operation.currentPageCell.items = self.dockItems
        operation.currentPageCell.draggedItem = operation.item
        
        operation.currentPageCell.collectionView.performBatchUpdates({
            operation.currentPageCell.collectionView.deleteItems(at: [operation.currentIndexPath])
        }, completion: nil)
        operation.currentPageCell.updateSectionInset()
        
        pageCell.items = self.items[self.currentPage]
        pageCell.draggedItem = operation.item
        pageCell.collectionView.performBatchUpdates({
            pageCell.collectionView.insertItems(at: [destinationIndexPath])
            
            if didMoveLastItem {
                pageCell.collectionView.deleteItems(at: [IndexPath(item: self.items[self.currentPage].count - 1, section: 0)])
            }
        }, completion: nil)
        
        operation.currentPageCell = pageCell
        operation.currentIndexPath = IndexPath(item: destinationIndexPath.row, section: 0)
    }
}
