//
//  SettingsViewController.swift
//  jSpringBoard
//
//  Created by Jota Melo on 30/08/17.
//  Copyright © 2017 jota. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {

    @IBOutlet var icons: [UIImageView]!
    
    var itemsManager: HomeItemsManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 11, *) {
            self.navigationController?.navigationBar.prefersLargeTitles = true
        }

        self.title = NSLocalizedString("Settings", comment: "")
        self.icons.forEach { $0.applyIconMask() }
        self.view.layoutIfNeeded()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "wallpaper" {
            let destination = segue.destination as! WallpaperViewController
            destination.itemsManager = self.itemsManager
        } else if segue.identifier == "manager" {
            let destination = segue.destination as! ItemsManagerViewController
            destination.itemsManager = self.itemsManager
        }
    }
    
    @objc func homeHandler() {
        self.dismiss(animated: true, completion: nil)
    }
}
