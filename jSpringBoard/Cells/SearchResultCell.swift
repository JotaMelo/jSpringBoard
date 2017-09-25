//
//  SearchResultCell.swift
//  jSpringBoard
//
//  Created by Jota Melo on 16/08/17.
//  Copyright © 2017 jota. All rights reserved.
//

import UIKit

class SearchResultCell: UITableViewCell {
    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var folderNameLabel: UILabel!
    @IBOutlet weak var separator: UIView!
    
    private(set) var searchResult: SearchResult?

    func setup(withResult result: SearchResult, hideSeparator: Bool) {
        
        self.searchResult = result
        self.nameLabel.text = result.app.name
        self.iconImageView.image = result.app.icon ?? #imageLiteral(resourceName: "default-icon")
        self.separator.isHidden = hideSeparator
        
        self.iconImageView.applyIconMask()
        
        if let folder = result.folder {
            self.folderNameLabel.isHidden = false
            self.folderNameLabel.text = folder.name
        } else {
            self.folderNameLabel.isHidden = true
        }
    }
}
