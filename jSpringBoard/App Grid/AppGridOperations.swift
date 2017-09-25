//
//  AppGridOperations.swift
//  jSpringBoard
//
//  Created by Jota Melo on 25/06/17.
//  Copyright © 2017 jota. All rights reserved.
//

import UIKit

class AppDragOperation {
    
    let item: HomeItem
    
    let originalPageCell: PageCell
    let originalIndexPath: IndexPath
    
    var currentPageCell: PageCell
    var currentIndexPath: IndexPath
    
    let placeholderView: HomeItemCellSnapshotView
    let dragOffset: CGSize
    
    var needsUpdate = false
    var savedState: [[HomeItem]]?
    
    required init(placeholderView: HomeItemCellSnapshotView, dragOffset: CGSize, item: HomeItem, originalPageCell: PageCell, originalIndexPath: IndexPath) {
        
        self.item = item
        
        self.originalPageCell = originalPageCell
        self.originalIndexPath = originalIndexPath
        
        self.currentPageCell = originalPageCell
        self.currentIndexPath = originalIndexPath
        
        self.placeholderView = placeholderView
        self.dragOffset = dragOffset
    }
    
    func applyOffset(to point: CGPoint) -> CGPoint {
        
        // is offseted a word?¿
        var offsettedTouchPoint = point
        offsettedTouchPoint.x += self.dragOffset.width
        offsettedTouchPoint.y += self.dragOffset.height
        return offsettedTouchPoint
    }
    
    func movePlaceholder(to point: CGPoint) {
        
        let offsettedTouchPoint = self.applyOffset(to: point)
        self.placeholderView.center = offsettedTouchPoint
    }
    
    func transitionToIconPlaceholder() {
        
        UIView.animate(withDuration: 0.2) {
            self.placeholderView.deleteButtonContainer?.alpha = 0
            self.placeholderView.badgeContainer.alpha = 0
            self.placeholderView.badgeOverlayView?.alpha = 0
            self.placeholderView.nameLabel.alpha = 0
        }
    }
    
    func transitionFromIconPlaceholder() {
        
        UIView.animate(withDuration: 0.2) {
            self.placeholderView.deleteButtonContainer?.alpha = 1
            self.placeholderView.badgeContainer.alpha = 1
            self.placeholderView.badgeOverlayView?.alpha = 1
            self.placeholderView.nameLabel.alpha = 1
        }
    }
    
    func copy() -> AppDragOperation {
        
        let newOperation = AppDragOperation(placeholderView: self.placeholderView, dragOffset: self.dragOffset, item: self.item, originalPageCell: self.originalPageCell, originalIndexPath: self.originalIndexPath)
        newOperation.currentPageCell = self.currentPageCell
        newOperation.currentIndexPath = self.currentIndexPath
        return newOperation
    }
}

struct AppDragOperationTransfer {
    var gestureRecognizer: UILongPressGestureRecognizer
    var operation: AppDragOperation
}

class OpenFolderInfo {
    var folder: Folder
    var cell: FolderCell
    var isNewFolder: Bool
    var shouldCancelCreation = false
    
    required init(cell: FolderCell, isNewFolder: Bool) {
        self.cell = cell
        self.folder = cell.item as! Folder
        self.isNewFolder = isNewFolder
    }
}

protocol FolderOperation: class {
    var dragOperation: AppDragOperation { get set }
    var item: HomeItem { get set }
    var isDismissing: Bool { get set }
    var placeholderView: UIView { get set }
}

class FolderCreationOperation: FolderOperation {
    
    var dragOperation: AppDragOperation
    var destinationApp: App
    var placeholderView: UIView
    var isDismissing: Bool = false
    
    var item: HomeItem
    
    required init(dragOperation: AppDragOperation, destinationApp: App, placeholderView: UIView) {
        self.dragOperation = dragOperation
        self.destinationApp = destinationApp
        self.item = destinationApp
        self.placeholderView = placeholderView
    }
}

class FolderDropOperation: FolderOperation {
    
    var dragOperation: AppDragOperation
    var folder: Folder
    var placeholderView: UIView
    var isDismissing: Bool = false
    
    var item: HomeItem
    
    required init(dragOperation: AppDragOperation, folder: Folder, placeholderView: UIView) {
        self.dragOperation = dragOperation
        self.folder = folder
        self.item = folder
        self.placeholderView = placeholderView
    }
}

class App3DTouchOperation {
    
    var viewController: HomeItemActionsViewController
    var cell: HomeItemCell
    var item: HomeItem
    
    required init(viewController: HomeItemActionsViewController, cell: HomeItemCell) {
        self.viewController = viewController
        self.cell = cell
        self.item = cell.item!
    }
}

class SettingsOpenOperation {

    var scrollView: UIScrollView
    var collectionSnapshotView: UIView
    var iconSnapshotView: UIView
    var viewControllerTransform: CGAffineTransform
    
    required init(scrollView: UIScrollView, collectionSnapshotView: UIView, iconSnapshotView: UIView, viewControllerTransform: CGAffineTransform) {
        self.scrollView = scrollView
        self.collectionSnapshotView = collectionSnapshotView
        self.iconSnapshotView = iconSnapshotView
        self.viewControllerTransform = viewControllerTransform
    }
}
