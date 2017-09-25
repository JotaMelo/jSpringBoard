//
//  ItemsManagerViewController.swift
//  jSpringBoard
//
//  Created by Jota Melo on 03/09/17.
//  Copyright © 2017 jota. All rights reserved.
//

import UIKit

class PaddedCell: UITableViewCell {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.imageView?.frame = self.imageView!.frame.insetBy(dx: 5, dy: 5)
    }
}

class ItemsManagerViewController: UITableViewController {
    
    var itemsManager: HomeItemsManager!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 11, *) {
            self.navigationItem.largeTitleDisplayMode = .never
        }

        self.tableView.allowsSelectionDuringEditing = true
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "OptionCell")
        self.tableView.register(PaddedCell.self, forCellReuseIdentifier: "ItemCell")
        self.tableView.reloadData()
        
        self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "appInfo" {
            let destination = segue.destination as! AppInfoViewController
            destination.app = sender as! App
            destination.itemsManager = self.itemsManager
        } else if segue.identifier == "folder" {
            let destination = segue.destination as! FolderManagerViewController
            destination.folder = sender as! Folder
            destination.itemsManager = self.itemsManager
        }
    }
    
    @objc func beginEditing() {
        self.tableView.setEditing(true, animated: true)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(endEditing))
    }
    
    @objc func endEditing() {
        self.tableView.setEditing(false, animated: true)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(beginEditing))
    }
}

// MARK: - UITableView data source / delegate

extension ItemsManagerViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.itemsManager.pages.count + 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0 {
            return 2
        } else if section == 1 {
            return self.itemsManager.dockItems.count;
        } else {
            return self.itemsManager.pages[section - 2].count
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if section == 1 {
            return "Dock"
        } else if section > 1 {
            return "Page \(section - 1)"
        }
        
        return nil
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "OptionCell", for: indexPath)
            cell.textLabel?.text = indexPath.row == 0 ? "Reset to default apps" : "Load apps from device"
            return cell
        } else {
            let item: HomeItem
            if indexPath.section == 1 {
                item = self.itemsManager.dockItems[indexPath.row]
            } else {
                item = self.itemsManager.pages[indexPath.section - 2][indexPath.row]
            }
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath)
            cell.accessoryType = .disclosureIndicator
            cell.showsReorderControl = true
            cell.shouldIndentWhileEditing = false
            
            if let app = item as? App {
                cell.textLabel?.text = item.name + (item.badge == nil ? "" : " (\(item.badge!))") // what am I doing
                cell.imageView?.image = MaskedIconCache.shared.maskedIcon(for: app)
                cell.imageView?.clipsToBounds = true
                cell.imageView?.contentMode = .scaleAspectFit
            } else {
                cell.textLabel?.text = "Folder: " + item.name
                cell.imageView?.image = nil
            }
            
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section > 0
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section > 0
    }
    
    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        
        if proposedDestinationIndexPath.section == 0 {
            return sourceIndexPath
        } else if sourceIndexPath.section == proposedDestinationIndexPath.section {
            return proposedDestinationIndexPath
        } else if proposedDestinationIndexPath.section == 1 && self.itemsManager.dockItems.count == Settings.shared.appsPerRow {
            return sourceIndexPath
        } else if proposedDestinationIndexPath.section >= 2 && self.itemsManager.pages[proposedDestinationIndexPath.section - 2].count == Settings.shared.appsPerPage {
            return sourceIndexPath
        }
        
        return proposedDestinationIndexPath
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        let item: HomeItem
        if sourceIndexPath.section == 1 {
            item = self.itemsManager.dockItems.remove(at: sourceIndexPath.row)
        } else {
            item = self.itemsManager.pages[sourceIndexPath.section - 2].remove(at: sourceIndexPath.row)
        }
        
        if destinationIndexPath.section == 1 {
            self.itemsManager.dockItems.insert(item, at: destinationIndexPath.row)
        } else {
            self.itemsManager.pages[destinationIndexPath.section - 2].insert(item, at: destinationIndexPath.row)
        }
        
        DispatchQueue.global(qos: .utility).async {
            self.itemsManager.persistToDisk()
        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        
        if indexPath.section == 1 {
            self.itemsManager.dockItems.remove(at: indexPath.row)
        } else {
            self.itemsManager.pages[indexPath.section - 2].remove(at: indexPath.row)
        }
        
        if indexPath.section > 1 && self.itemsManager.pages[indexPath.section - 2].count == 0 {
            self.itemsManager.pages.remove(at: indexPath.section - 2)
            tableView.deleteSections([indexPath.section], with: .automatic)
        } else {
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        
        DispatchQueue.global(qos: .utility).async {
            self.itemsManager.persistToDisk()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                self.itemsManager.loadLocal()
            } else {
                if #available(iOS 11, *) {
                    let alertController = UIAlertController(title: NSLocalizedString("Hey, so...", comment: ""), message: NSLocalizedString("The private API used for this feature (which loaded all of YOUR apps) stopped working on iOS 11.", comment: ""), preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                } else {
                    self.itemsManager.loadFromDevice()
                }
            }
            
            self.tableView.reloadData()
            DispatchQueue.global(qos: .utility).async {
                self.itemsManager.persistToDisk()
            }
        } else {
            let item: HomeItem
            if indexPath.section == 1 {
                item = self.itemsManager.dockItems[indexPath.row]
            } else {
                item = self.itemsManager.pages[indexPath.section - 2][indexPath.row]
            }
            
            if item is App {
                self.performSegue(withIdentifier: "appInfo", sender: item)
            } else if item is Folder {
                self.performSegue(withIdentifier: "folder", sender: item)
            }
        }
    }
}
