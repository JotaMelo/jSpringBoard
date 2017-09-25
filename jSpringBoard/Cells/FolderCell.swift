//
//  FolderCell.swift
//  jSpringBoard
//
//  Created by Jota Melo on 15/06/17.
//  Copyright © 2017 jota. All rights reserved.
//

import UIKit

class FolderCell: HomeItemCell {
    
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var blurView: UIVisualEffectView!
    
    var currentPage: Int {
        return Int(self.collectionView.contentOffset.x) / Int(self.collectionView.frame.size.width)
    }
    
    private var items: [[App]] = [] {
        didSet {
            self.collectionView.reloadData()
        }
    }
    
    private var placeholderView: UIView?
    
    override func updateUI() {
        super.updateUI()
        guard let folder = self.item as? Folder else { return }
        
        // when creating a new folder the blur mask needs to
        // be created immediatly beucase in this case it does
        // work and to prevent weird glithces in the animation
        // (check large comment on the bottom of PageCell for more)
        // (and yes this is a GOTO COMMENT pardon me)
        if folder.isNewFolder && self.blurView.mask == nil {
            if #available(iOS 11, *) {
                self.blurView.applyIconMask()
            } else {
                self.blurView.applyIconMaskView()
            }
        }
        
        // cleaning up possible mess from animateToFolderCreationCancelState
        self.placeholderView?.removeFromSuperview()
        self.iconContainerView.transform = .identity
        
        self.items = folder.pages
        self.collectionView.reloadData()
    }
    
    override func leaveEditingMode() {
        super.leaveEditingMode()
        
        if let folder = self.item as? Folder, self.items[self.items.count - 1].count == 0 {
            self.items.removeLast()
            folder.pages = self.items
            self.collectionView.reloadData()
        }
    }
    
    override func snapshotView() -> HomeItemCellSnapshotView {
        // this needs to be overridden because taking snapshots of a UIVisualEffectView
        // is not that easy. As Apple notes here:
        // https://developer.apple.com/documentation/uikit/uivisualeffectview
        // "To take a snapshot of a view hierarchy that contains a UIVisualEffectView
        // you must take a snapshot of the entire UIWindow ou UIScreen that contains it."
        // So I thought it was better to recreate that blur in the FolderCell snapshot,
        // by grabbing the part of the wallpaper right behind it, creating another
        // UIVisualEffectView etc.
        
        self.blurView.isHidden = true
        let snapshotView = super.snapshotView()
        self.blurView.isHidden = false
        
        let convertedIconFrame = self.convert(self.iconContainerView.frame, to: self.superview!)
        let wallpaperSnapshot = Settings.shared.snapshotOfWallpaper(at: convertedIconFrame)!
        
        let wallpaperImageView = UIImageView(image: wallpaperSnapshot)
        wallpaperImageView.frame = snapshotView.iconView.frame
        wallpaperImageView.clipsToBounds = true
        wallpaperImageView.applyIconMask()
        snapshotView.insertSubview(wallpaperImageView, belowSubview: snapshotView.iconView)
        
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        blurView.frame = wallpaperImageView.frame
        
        // if I don't do this the image leaks out of the blur a little
        // bit (exactly 1px (yes, pixel)) on the plus models
        if UIScreen.main.scale == 3 {
            blurView.frame.size.width += (1 / 3)
        }
        
        snapshotView.insertSubview(blurView, aboveSubview: wallpaperImageView)
        
        if #available(iOS 11, *) {
            blurView.applyIconMask()
        } else {
            blurView.applyIconMaskView()
        }
        
        return snapshotView
    }
    
    func moveToFirstAvailablePage(animated: Bool = true) {
        
        if let folder = self.item as? Folder, self.items[self.items.count - 1].count > 0 {
            folder.pages.append([])
            self.items.append([])
        }
        
        let appsPerPage = Settings.shared.appsPerPageOnFolder
        for (index, page) in self.items.enumerated() {
            if page.count < appsPerPage {
                if index != self.currentPage {
                    self.moveTo(page: index, animated: animated)
                }
                
                break
            }
        }
    }
    
    func moveTo(page: Int, animated: Bool) {
        guard page < self.items.count else { return }
        
        let indexPath = IndexPath(item: page, section: 0)
        self.collectionView.scrollToItem(at: indexPath, at: .left, animated: animated)
    }
    
    func move(view: UIView, toCellPositionAtIndex index: Int, completion: (() -> Void)? = nil) {
        guard let currentPageCell = self.collectionView.cellForItem(at: IndexPath(item: self.currentPage, section: 0)) as? PageCell,
            let flowLayout = currentPageCell.collectionView.collectionViewLayout as? UICollectionViewFlowLayout,
            let layoutAttributes = flowLayout.layoutAttributesForItem(at: IndexPath(item: index, section: 0)) else { return }
        
        // when we're at a blank page that's ≠ 0, layoutAttributesForItem.frame will return
        // x = 0 for the first item. Why? Who the fuck knows, but let's adjust it.
        if layoutAttributes.frame.minX == 0 {
            layoutAttributes.frame.origin.x = flowLayout.sectionInset.left
        }
        
        let convertedRect1 = self.convert(layoutAttributes.frame, from: currentPageCell)
        let convertedRect2 = self.convert(convertedRect1, to: view.superview!)
        
        UIView.animate(withDuration: 0.35, animations: {
            view.frame = convertedRect2
        }, completion: { _ in
            completion?()
        })
    }
    
    // what the hell is this name really
    func animateToFolderCreationCancelState(completion: @escaping () -> Void) {
        guard let currentPageCell = self.collectionView.cellForItem(at: IndexPath(item: self.currentPage, section: 0)) as? PageCell,
            let itemCell = currentPageCell.collectionView.cellForItem(at: IndexPath(item: 0, section: 0)) as? HomeItemCell else { return }
        
        let convertedRect1 = currentPageCell.convert(itemCell.iconImageView!.frame, from: itemCell)
        let convertedRect2 = self.convert(convertedRect1, from: currentPageCell)
        
        let imageView = UIImageView(frame: convertedRect2)
        imageView.image = itemCell.iconImageView!.image
        imageView.applyIconMask()
        self.contentView.addSubview(imageView)
        itemCell.iconImageView!.isHidden = true
        
        UIView.animate(withDuration: 0.55, animations: {
            imageView.transform = .transform(rect: imageView.frame, to: self.iconContainerView.frame)
            self.iconContainerView.transform = CGAffineTransform.identity.scaledBy(x: 0.01, y: 0.01)
            self.nameLabel?.alpha = 0
        }, completion: { _ in
            self.placeholderView = imageView
            itemCell.iconImageView!.isHidden = false
            completion()
        })
    }
}

extension FolderCell: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PageCell", for: indexPath) as! PageCell
        cell.draggedItem = nil
        cell.items = self.items[indexPath.row]
        cell.collectionView.reloadData()
        return cell
    }
}

