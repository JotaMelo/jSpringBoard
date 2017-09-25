//
//  PageCell.swift
//  jSpringBoard
//
//  Created by Jota Melo on 15/06/17.
//  Copyright © 2017 jota. All rights reserved.
//

import UIKit

enum PageMode {
    case regular
    case folder
    case dock
}

protocol PageCellDelegate: class {
    func didSelect(cell: HomeItemCell, on pageCell: PageCell)
    func didTapDelete(forItem item: HomeItem, on pageCell: PageCell)
}

class PageCell: UICollectionViewCell {
    
    @IBOutlet var collectionView: UICollectionView!
    
    weak var delegate: PageCellDelegate?
    var mode: PageMode = .regular {
        didSet {
            self.updateLayout()
        }
    }
    
    var items: [HomeItem] = []
    var draggedItem: HomeItem?
    private var isEditing = false
    
    func updateLayout() {
        
        let flowLayout = self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        flowLayout.itemSize = Settings.shared.cellSize
        
        if self.mode == .dock {
            flowLayout.sectionInset = UIEdgeInsets(top: Settings.shared.dockTopMargin, left: Settings.shared.horizontalMargin, bottom: 0, right: Settings.shared.horizontalMargin)
            self.updateSectionInset()
        } else if self.mode == .regular {
            flowLayout.sectionInset = UIEdgeInsets(top: Settings.shared.topMargin, left: Settings.shared.horizontalMargin, bottom: 0, right: Settings.shared.horizontalMargin)
            flowLayout.minimumLineSpacing = Settings.shared.lineSpacing
        }
    }
    
    func enterEditingMode() {
        guard !self.isEditing else { return }
        
        self.isEditing = true
        for cell in self.collectionView.visibleCells {
            let cell = cell as! HomeItemCell
            cell.animate()
            cell.enterEditingMode()
            
            if let cell = cell as? FolderCell {
                cell.moveToFirstAvailablePage()
            }
        }
    }
    
    func leaveEditingMode() {
        guard self.isEditing else { return }
        
        self.isEditing = false
        for cell in self.collectionView.visibleCells {
            let cell = cell as! HomeItemCell
            cell.stopAnimation()
            cell.leaveEditingMode()
            
            if let cell = cell as? FolderCell {
                cell.moveTo(page: 0, animated: true)
            }
        }
    }
    
    func updateSectionInset() {
        guard let flowLayout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout, self.mode == .dock else { return }
        
        let newHorizontalSectionInset: CGFloat
        let appsPerRow = CGFloat(Settings.shared.appsPerRow)
        let interitemSpacing = (self.frame.width - (Settings.shared.horizontalMargin * 2) - (appsPerRow * flowLayout.itemSize.width)) / (appsPerRow - 1)
        
        if self.items.count < Settings.shared.appsPerRow {
            let count = CGFloat(self.items.count)
            let totalSpace = (flowLayout.itemSize.width * count) + (interitemSpacing * (count - 1))
            newHorizontalSectionInset = (self.frame.size.width - totalSpace) / 2
        } else {
            newHorizontalSectionInset = Settings.shared.horizontalMargin
        }
        
        self.collectionView.performBatchUpdates({
            flowLayout.sectionInset = UIEdgeInsets(top: 0, left: newHorizontalSectionInset, bottom: 0, right: newHorizontalSectionInset)
        }, completion: nil)
    }
    
    func delete(item: HomeItem) {
        guard let index = self.items.index(where: { $0 === item }), let cell = self.collectionView.cellForItem(at: IndexPath(item: index, section: 0)) else { return }
        
        UIView.animate(withDuration: 0.25, animations: {
            cell.contentView.transform = CGAffineTransform.identity.scaledBy(x: 0.0001, y: 0.0001)
        }, completion: { _ in
            self.items.remove(at: index)
            self.collectionView.performBatchUpdates({
                self.collectionView.deleteItems(at: [IndexPath(item: index, section: 0)])
            }, completion: { _ in
                cell.contentView.transform = .identity
            })
            
            if self.mode == .dock {
                self.updateSectionInset()
            }
        })
    }
}

extension PageCell: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if let folder = self.items[indexPath.row] as? Folder {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FolderCell", for: indexPath) as! FolderCell
            cell.item = folder
            
            if self.isEditing {
                cell.animate()
                cell.enterEditingMode()
                cell.moveToFirstAvailablePage(animated: false)
            } else {
                cell.stopAnimation()
                cell.leaveEditingMode()
            }
            
            if let draggedItem = self.draggedItem, draggedItem === folder {
                cell.contentView.isHidden = true
            } else {
                cell.contentView.isHidden = false
            }
            
            return cell
        } else if let app = self.items[indexPath.row] as? App {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AppCell", for: indexPath) as! HomeItemCell
            
            if self.isEditing {
                cell.animate()
                cell.enterEditingMode()
            } else {
                cell.stopAnimation()
                cell.leaveEditingMode()
            }
            
            if let draggedItem = self.draggedItem, draggedItem === app {
                cell.contentView.isHidden = true
            } else {
                cell.contentView.isHidden = false
            }
            
            cell.item = app
            cell.delegate = self
            
            if self.mode == .dock && Settings.shared.isD22 {
                cell.nameLabel?.isHidden = true
            }
            
            return cell
        }
        
        // not really possible
        return collectionView.dequeueReusableCell(withReuseIdentifier: "wat", for: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.delegate?.didSelect(cell: collectionView.cellForItem(at: indexPath) as! HomeItemCell, on: self)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        if let cell = cell as? FolderCell, cell.blurView.mask == nil {
            // This most definitely will go wrong sometime (likely in older devices),
            // or even cause visible glitches on modern devices when showing a folder
            // cell because apparently blur is fucking hard.
            // Problem: a FolderCell's background is blurred, but it needs to be
            // masked with the default icon mask. You can't mask the layer of a
            // UIVisualEffectView, it'll just break (just like when you mess with
            // its alpha). You have to set the maskView for it to work. So far ok,
            // but the problem is now a different one: when to set that mask?
            // If you set it on awakeFromNib it will just make the effect disappear
            // completely. Not even broken, just invisible. Apparently I have to wait
            // until the cell is at least a little bit on screen for that to work.
            // I tried putting it in didMoveToWindow, didMoveToSuperview etc, nothing.
            // So I just use my default hack: wait.
            // It might have something to do with this offscreen pass stuff mentioned here:
            // https://forums.developer.apple.com/thread/50854#159049
            // It must be fun making UIVisualEffectView
            // (note: on iOS 11 settings UIView's mask just doesn't work anymore on the visual
            // effect view, but masking the layer does! Go figure)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                if #available(iOS 11, *) {
                    cell.blurView.applyIconMask()
                } else {
                    cell.blurView.applyIconMaskView()
                }
            })
        }
    }
}

// MARK: - Home Item Cell delegate

extension PageCell: HomeItemCellDelegate {
    func didTapDelete(on cell: HomeItemCell) {
        guard let item = cell.item else { return }
        self.delegate?.didTapDelete(forItem: item, on: self)
    }
}
