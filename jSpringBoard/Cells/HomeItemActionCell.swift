//
//  HomeItemActionCell.swift
//  jSpringBoard
//
//  Created by Jota Melo on 26/07/17.
//  Copyright © 2017 jota. All rights reserved.
//

import UIKit

class HomeItemActionCell: UITableViewCell {

    @IBOutlet var iconImageView: UIImageView!
    @IBOutlet var itemTitleLabel: UILabel!
    @IBOutlet var badgeLabel: UILabel!
    
    var item: HomeItemAction? {
        didSet {
            self.setupUI()
        }
    }
    
    func setupUI() {
        guard let item = self.item else { return }
        
        self.itemTitleLabel.text = item.title
        if let badge = item.badge {
            self.badgeLabel.text = "\(badge)"
            self.iconImageView.image = item.icon
            self.badgeLabel.superview?.isHidden = false
        } else {
            self.iconImageView.image = item.icon.withRenderingMode(.alwaysTemplate)
            self.badgeLabel.superview?.isHidden = true
        }
    }
}
