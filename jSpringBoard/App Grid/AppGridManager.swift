//
//  AppGridManager.swift
//  jSpringBoard
//
//  Created by Jota Melo on 18/06/17.
//  Copyright © 2017 jota. All rights reserved.
//

import UIKit

protocol AppGridManagerDelegate: class {
    func didUpdateItems(on manager: AppGridManager)
    func didUpdate(pageCount: Int, on manager: AppGridManager)
    func didMove(toPage page: Int, on manager: AppGridManager)
    func collectionViewDidScroll(_ collectionView: UICollectionView, on manager: AppGridManager)
    
    func didEnterEditingMode(on manager: AppGridManager)
    func didBeginFolderDragOut(transfer: AppDragOperationTransfer, on manager: AppGridManager)
    
    func didDelete(item: HomeItem, on manager: AppGridManager)
    func didSelect(app: App, on manager: AppGridManager)
    func openSettings(fromSnapshotView snapshotView: UIView, on manager: AppGridManager)
}

class AppGridManager: NSObject {
    
    weak var delegate: AppGridManagerDelegate?
    var currentPage: Int {
        return Int(self.mainCollectionView.contentOffset.x) / Int(self.mainCollectionView.frame.size.width)
    }
    var currentPageCell: PageCell {
        let visibleCells = self.mainCollectionView.visibleCells
        if visibleCells.count == 0 {
            return self.mainCollectionView.subviews[0] as! PageCell
        } else {
            return visibleCells[0] as! PageCell
        }
    }
    
    unowned var viewController: UIViewController
    unowned var mainCollectionView: UICollectionView
    weak var dockCollectionView: UICollectionView?
    var longPressRecognizer: UILongPressGestureRecognizer
    var threeDTouchRecognizer: ThreeDTouchGestureRecognizer
    
    var items: [[HomeItem]] {
        didSet {
            self.delegate?.didUpdate(pageCount: self.items.count, on: self)
            self.delegate?.didUpdateItems(on: self)
        }
    }
    
    var dockItems: [HomeItem] {
        didSet {
            self.delegate?.didUpdateItems(on: self)
        }
    }
    
    var feedbackGenerator = UIImpactFeedbackGenerator()
    var isEditing = false
    
    var pageTimer: Timer?
    var folderTimer: Timer?
    var folderRemovalTimer: Timer?
    
    var currentDragOperation: AppDragOperation?
    var currentFolderOperation: FolderOperation?
    var current3DTouchOperation: App3DTouchOperation?
    var openFolderInfo: OpenFolderInfo?
    
    // when you drag an app to a folder and when the folder opens
    // the app happens to be just outside the folder region we have
    // to ignore the default "begin drag out" action.
    var ignoreDragOutOnTop = false
    var ignoreDragOutOnBottom = false
    
    init(viewController: UIViewController, mainCollectionView: UICollectionView, items: [[HomeItem]], dockCollectionView: UICollectionView? = nil, dockItems: [HomeItem] = []) {
        
        self.viewController = viewController
        
        self.mainCollectionView = mainCollectionView
        self.dockCollectionView = dockCollectionView
        
        self.items = items
        self.dockItems = dockItems
        
        self.longPressRecognizer = UILongPressGestureRecognizer()
        self.threeDTouchRecognizer = ThreeDTouchGestureRecognizer()
        self.threeDTouchRecognizer.cancelsTouchesInView = true
        
        super.init()
        
        self.mainCollectionView.dataSource = self
        self.mainCollectionView.delegate = self
        self.mainCollectionView.prefetchDataSource = self
            
        self.dockCollectionView?.dataSource = self
        self.dockCollectionView?.delegate = self
        
        self.longPressRecognizer.addTarget(self, action: #selector(handleLongGesture(_:)))
        self.threeDTouchRecognizer.addTarget(self, action: #selector(handle3DTouchGesture(_:)))
        self.viewController.view.addGestureRecognizer(self.threeDTouchRecognizer)
        self.viewController.view.addGestureRecognizer(self.longPressRecognizer)
    }
    
    // don't really like this name
    func collectionViewAndPageCell(at point: CGPoint) -> (collectionView: UICollectionView, cell: PageCell) {
        
        let collectionView: UICollectionView
        if let dockCollectionView = self.dockCollectionView, dockCollectionView.frame.contains(self.viewController.view.convert(point, to: dockCollectionView)) {
            collectionView = dockCollectionView
        } else {
            collectionView = self.mainCollectionView
        }
        
        let convertedPoint = self.viewController.view.convert(point, to: collectionView)
        if let indexPath = collectionView.indexPathForItem(at: convertedPoint), let cell = collectionView.cellForItem(at: indexPath) as? PageCell {
            return (collectionView, cell)
        } else {
            return (collectionView, collectionView.visibleCells[0] as! PageCell)
        }
    }
    
    func enterEditingMode(suppressHaptic: Bool = false) {
        guard !self.isEditing else { return }
        
        if !suppressHaptic {
            self.feedbackGenerator.impactOccurred()
        }
        
        self.isEditing = true
        self.viewController.view.removeGestureRecognizer(self.threeDTouchRecognizer)
        
        for cell in self.mainCollectionView.visibleCells + (self.dockCollectionView?.visibleCells ?? []) {
            let cell = cell as! PageCell
            cell.enterEditingMode()
        }
        
        if self.items[self.items.count - 1].count > 0 {
            self.items.append([])
            self.mainCollectionView.insertItems(at: [IndexPath(item: self.items.count - 1, section: 0)])
        }
        
        self.delegate?.didEnterEditingMode(on: self)
    }
    
    func leaveEditingMode() {
        guard self.isEditing else { return }
        
        self.isEditing = false
        self.viewController.view.addGestureRecognizer(self.threeDTouchRecognizer)
        
        for cell in self.mainCollectionView.visibleCells + (self.dockCollectionView?.visibleCells ?? []) {
            let cell = cell as! PageCell
            cell.leaveEditingMode()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            if self.items[self.items.count - 1].count == 0 {
                self.items.removeLast()
                self.mainCollectionView.deleteItems(at: [IndexPath(item: self.items.count, section: 0)])
            }
        }
    }
    
    @objc func pageTimerHandler(_ timer: Timer) {
        guard let currentOperation = self.currentDragOperation, let offset = timer.userInfo as? Int else { return }
        
        self.pageTimer = nil
        guard let currentIndex = self.items[self.currentPage].index(where: { $0 === currentOperation.item }) else { return }
        let currentPageInitialCount = self.items[self.currentPage].count
        let nextPage = self.currentPage + offset
        
        if nextPage < 0 || nextPage > self.items.count - 1 {
            return
        }
        
        if let savedState = currentOperation.savedState {
            self.items = savedState
            currentOperation.savedState = nil
        } else {
            self.items[self.currentPage].remove(at: currentIndex)
        }
        
        let appsPerPage = self.dockCollectionView == nil ? Settings.shared.appsPerPageOnFolder : Settings.shared.appsPerPage
        if self.items[nextPage].count == appsPerPage {
            currentOperation.savedState = self.items
            self.moveLastItem(inPage: nextPage)
        }
        
        self.items[nextPage].append(currentOperation.item)
        
        currentOperation.currentPageCell.items = self.items[self.currentPage]
        currentOperation.needsUpdate = true
        
        if currentOperation.currentPageCell == currentOperation.originalPageCell && self.items[self.currentPage].count < currentPageInitialCount {
            currentOperation.currentPageCell.collectionView.performBatchUpdates({
                currentOperation.currentPageCell.collectionView.deleteItems(at: [IndexPath(item: currentIndex, section: 0)])
            }, completion: nil)
        } else {
            currentOperation.currentPageCell.collectionView.reloadData()
        }
        
        var newContentOffset = self.mainCollectionView.contentOffset
        newContentOffset.x = self.mainCollectionView.frame.width * CGFloat(self.currentPage + offset)
        self.mainCollectionView.setContentOffset(newContentOffset, animated: true)
    }
    
    // moves last item in page to next and rearranges next pages if needed
    func moveLastItem(inPage page: Int) {
        
        var currentPage = self.items[page + 1]
        currentPage.insert(self.items[page].removeLast(), at: 0)
        self.items[page + 1] = currentPage
        
        let appsPerPage = self.dockCollectionView == nil ? Settings.shared.appsPerPageOnFolder : Settings.shared.appsPerPage
        if currentPage.count > appsPerPage {
            self.moveLastItem(inPage: page + 1)
        }
    }
    
    func updateState(forPageCell pageCell: PageCell) {
        
        var collectionView: UICollectionView
        if let dockCollectionView = self.dockCollectionView, dockCollectionView.visibleCells.contains(pageCell) {
            collectionView = dockCollectionView
        } else {
            collectionView = self.mainCollectionView
        }
        
        var items: [HomeItem] = []
        for i in 0..<pageCell.collectionView.visibleCells.count {
            let indexPath = IndexPath(item: i, section: 0)
            if let cell = pageCell.collectionView.cellForItem(at: indexPath) as? HomeItemCell, let item = cell.item {
                items.append(item)
            }
        }
        
        if collectionView == self.mainCollectionView {
            guard let pageIndexPath = collectionView.indexPath(for: pageCell) else { return }
            self.items[pageIndexPath.row] = items
        } else {
            self.dockItems = items
        }
        
        pageCell.items = items
    }
    
    func perform(transfer: AppDragOperationTransfer) {
        
        self.viewController.view.removeGestureRecognizer(self.longPressRecognizer)
        
        self.longPressRecognizer = transfer.gestureRecognizer
        self.longPressRecognizer.removeTarget(nil, action: nil)
        self.longPressRecognizer.addTarget(self, action: #selector(handleLongGesture(_:)))
        self.viewController.view.addGestureRecognizer(self.longPressRecognizer)
        
        self.currentDragOperation = transfer.operation.copy()
        self.currentDragOperation?.needsUpdate = true
        UIApplication.shared.keyWindow!.addSubview(transfer.operation.placeholderView)
    }
    
    func homeAction() {
        if self.isEditing {
            self.leaveEditingMode()
        } else if self.currentPage > 0 && self.viewController.presentedViewController == nil {
            self.mainCollectionView.setContentOffset(.zero, animated: true)
        }
    }
}

// MARK: - Scroll View delegate

extension AppGridManager: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let page = scrollView.contentOffset.x / scrollView.frame.width
        self.delegate?.didMove(toPage: Int(roundf(Float(page))), on: self)
        self.delegate?.collectionViewDidScroll(self.mainCollectionView, on: self)
    }
}

// MARK: - Page Cell delegate

extension AppGridManager: PageCellDelegate {
    
    func didSelect(cell: HomeItemCell, on pageCell: PageCell) {
        
        if let cell = cell as? FolderCell {
            self.showFolder(from: cell)
        } else if let item = cell.item as? App, item.bundleID == "com.apple.Preferences" && !self.isEditing {
            var convertedFrame = self.mainCollectionView.convert(cell.iconContainerView.frame, from: cell)
            convertedFrame.origin.x -= self.mainCollectionView.contentOffset.x
            let iconSnapshot = cell.iconContainerView.snapshotView(afterScreenUpdates: true)!
            iconSnapshot.frame = convertedFrame
            self.delegate?.openSettings(fromSnapshotView: iconSnapshot, on: self)
        } else if let item = cell.item as? App, !self.isEditing {
            self.delegate?.didSelect(app: item, on: self)
        }
    }
    
    func didTapDelete(forItem item: HomeItem, on pageCell: PageCell) {
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .default, handler: nil)
        let deleteAction = UIAlertAction(title: NSLocalizedString("Delete", comment: ""), style: .destructive) { action in
            self.updateState(forPageCell: pageCell)
            if self.mainCollectionView.visibleCells.contains(pageCell), let indexPath = self.mainCollectionView.indexPath(for: pageCell), let itemIndex = self.items[indexPath.row].index(where: { $0 === item }) {
                pageCell.items = self.items[indexPath.row]
                self.items[indexPath.row].remove(at: itemIndex)
            } else if let dockCollectionView = self.dockCollectionView, dockCollectionView.visibleCells.contains(pageCell), let itemIndex = self.dockItems.index(where: { $0 === item }) {
                pageCell.items = self.dockItems
                self.dockItems.remove(at: itemIndex)
            }
            
            pageCell.delete(item: item)
            self.delegate?.didDelete(item: item, on: self)
        }
        
        let alertController = UIAlertController(title: NSLocalizedString("Delete \"\(item.name)\"?", comment: ""), message: NSLocalizedString("Deleting this app will also delete its data.", comment: ""), preferredStyle: .alert)
        alertController.addAction(cancelAction)
        alertController.addAction(deleteAction)
        alertController.preferredAction = deleteAction
        self.viewController.present(alertController, animated: true, completion: nil)
    }
}

// MARK: - Collection View delegate / data source

extension AppGridManager: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDataSourcePrefetching {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if collectionView == self.mainCollectionView {
            return self.items.count
        } else {
            return 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let items = collectionView == self.mainCollectionView ? self.items[indexPath.row] : self.dockItems
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PageCell", for: indexPath) as! PageCell
        cell.items = items
        cell.draggedItem = self.currentDragOperation?.item
        cell.delegate = self
        cell.collectionView.reloadData()
        
        if self.dockCollectionView == nil {
            cell.mode = .folder
        } else {
            cell.mode = collectionView == self.mainCollectionView ? .regular : .dock
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        let cell = cell as! PageCell
        
        if let currentOperation = self.currentDragOperation, currentOperation.needsUpdate {
            cell.items = self.items[indexPath.row]
            currentOperation.currentPageCell = cell
            currentOperation.currentIndexPath = IndexPath(item: cell.collectionView(cell.collectionView, numberOfItemsInSection: 0) - 1, section: 0)
            currentOperation.needsUpdate = false
        }
        
        cell.draggedItem = self.currentDragOperation?.item
        cell.collectionView.reloadData()
        
        if self.isEditing {
            cell.enterEditingMode()
        } else {
            cell.leaveEditingMode()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        let cell = cell as! PageCell
        if self.isEditing {
            cell.leaveEditingMode()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) { }
}
