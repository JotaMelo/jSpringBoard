//
//  FolderManagerViewController.swift
//  jSpringBoard
//
//  Created by Jota Melo on 07/09/17.
//  Copyright © 2017 jota. All rights reserved.
//

import UIKit

class FolderManagerViewController: UITableViewController {
    
    var folder: Folder!
    var itemsManager: HomeItemsManager!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 11, *) {
            self.navigationItem.largeTitleDisplayMode = .never
        }

        self.title = self.folder.name
        self.tableView.register(PaddedCell.self, forCellReuseIdentifier: "ItemCell")
        self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "appInfo" {
            let destination = segue.destination as! AppInfoViewController
            destination.app = sender as! App
            destination.folder = self.folder
            destination.itemsManager = self.itemsManager
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.folder.pages.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.folder.pages[section].count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Page \(section + 1)"
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let app = self.folder.pages[indexPath.section][indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath)
        cell.accessoryType = .disclosureIndicator
        cell.showsReorderControl = true
        cell.shouldIndentWhileEditing = false
        
        cell.textLabel?.text = app.name + (app.badge == nil ? "" : " (\(app.badge!))")
        cell.imageView?.image = MaskedIconCache.shared.maskedIcon(for: app)
        cell.imageView?.clipsToBounds = true
        cell.imageView?.contentMode = .scaleAspectFit
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        
        if sourceIndexPath.section == proposedDestinationIndexPath.section {
            return proposedDestinationIndexPath
        } else if self.folder.pages[proposedDestinationIndexPath.section].count == Settings.shared.appsPerPageOnFolder {
            return sourceIndexPath
        }
        
        return proposedDestinationIndexPath
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        let app = self.folder.pages[sourceIndexPath.section].remove(at: sourceIndexPath.row)
        self.folder.pages[destinationIndexPath.section].insert(app, at: destinationIndexPath.row)
        
        DispatchQueue.global(qos: .utility).async {
            self.itemsManager.persistToDisk()
        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        
        self.folder.pages[indexPath.section].remove(at: indexPath.row)
        
        if self.folder.pages[indexPath.section].count == 0 {
            self.folder.pages.remove(at: indexPath.section)
            tableView.deleteSections([indexPath.section], with: .automatic)
        } else {
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        
        DispatchQueue.global(qos: .utility).async {
            self.itemsManager.persistToDisk()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "appInfo", sender: self.folder.pages[indexPath.section][indexPath.row])
    }
}
