//
//  AppInfoViewController.swift
//  jSpringBoard
//
//  Created by Jota Melo on 03/09/17.
//  Copyright © 2017 jota. All rights reserved.
//

import UIKit

class AppInfoViewController: UIViewController {

    @IBOutlet var nameTextField: UITextField!
    @IBOutlet var bundleIDTextField: UITextField!
    @IBOutlet var badgeTextField: UITextField!
    @IBOutlet var badgeStepper: UIStepper!
    @IBOutlet var threeDTouchSwitch: UISwitch!
    @IBOutlet var iconImageView: UIImageView!
    
    @IBOutlet var moveToFolderButton: UIButton!
    @IBOutlet var moveOutOfFolderButton: UIButton!
    
    private lazy var imagePickerController: UIImagePickerController = {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        picker.delegate = self
        return picker
    }()
    
    var app: App!
    var folder: Folder?
    var itemsManager: HomeItemsManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 11, *) {
            self.navigationItem.largeTitleDisplayMode = .never
        }

        self.title = self.app.name
        self.nameTextField.text = self.app.name
        self.bundleIDTextField.text = self.app.bundleID
        self.badgeStepper.value = Double(self.app.badge ?? -1)
        self.badgeValueChanged(self.badgeStepper)
        self.threeDTouchSwitch.isOn = self.app.isShareable
        self.iconImageView.image = self.app.icon ?? #imageLiteral(resourceName: "default-icon")
        self.iconImageView.applyIconMask()
        
        if self.folder != nil {
            self.moveToFolderButton.isHidden = true
        } else {
            self.moveOutOfFolderButton.isHidden = true
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        DispatchQueue.global(qos: .utility).async {
            self.itemsManager.persistToDisk()
        }
    }
    
    func moveTo(folder: Folder) {
        
        let appLocation = self.itemsManager.location(of: self.app)
        self.itemsManager.add(app: self.app, to: folder)
        if let appLocation = appLocation, appLocation.type == .main {
            self.itemsManager.pages[appLocation.indexPath.section].remove(at: appLocation.indexPath.row)
        }
        
        var viewControllersStack = self.navigationController!.viewControllers
        viewControllersStack.removeLast()
        
        let folderViewController = self.storyboard?.instantiateViewController(withIdentifier: "FolderManagerViewController") as! FolderManagerViewController
        folderViewController.folder = folder
        folderViewController.itemsManager = self.itemsManager
        viewControllersStack.append(folderViewController)
        self.navigationController?.setViewControllers(viewControllersStack, animated: true)
    }

    @IBAction func didEndEditingName(_ sender: Any) {
        
        if let text = self.nameTextField.text, self.nameTextField.hasText {
            self.app.name = text
        }
    }
    
    @IBAction func didEndEditingBundleID(_ sender: Any) {
        
        if let text = self.bundleIDTextField.text, self.bundleIDTextField.hasText {
            self.app.bundleID = text
        }
    }
    
    @IBAction func badgeValueChanged(_ sender: Any) {
        
        self.app.badge = Int(self.badgeStepper.value)
        if self.badgeStepper.value == 0 {
            self.badgeTextField.text = NSLocalizedString("Empty (voicemail badge)", comment: "")
        } else if self.badgeStepper.value == -1 {
            self.badgeTextField.text = NSLocalizedString("No badge", comment: "")
            self.app.badge = nil
        } else {
            self.badgeTextField.text = "\(Int(self.badgeStepper.value))"
        }
    }
    
    @IBAction func threeDTouchValueChanged(_ sender: Any) {
        self.app.isShareable = self.threeDTouchSwitch.isOn
    }
    
    @IBAction func changeIcon(_ sender: Any) {
        self.present(self.imagePickerController, animated: true, completion: nil)
    }
    
    @IBAction func moveToFolder(_ sender: Any) {
        
        let folders = self.itemsManager.pages.flatMap({ $0 }).flatMap { $0 as? Folder }
        let alertController = UIAlertController(title: NSLocalizedString("Move to Folder", comment: ""), message: NSLocalizedString("Select a folder to move \(self.app.name)", comment: ""), preferredStyle: .actionSheet)
        for folder in folders {
            let action = UIAlertAction(title: folder.name, style: .default, handler: { _ in
                self.moveTo(folder: folder)
            })
            alertController.addAction(action)
        }
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func moveOutOfFolder(_ sender: Any) {
        guard let folder = self.folder else { return }
        
        self.itemsManager.add(app: self.app)
        self.itemsManager.remove(app: self.app, from: folder)
        
        var viewControllersStack = self.navigationController!.viewControllers
        self.navigationController?.popToViewController(viewControllersStack[viewControllersStack.count - 3], animated: true)
    }
}

// MARK: - Text Field delegate

extension AppInfoViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - Image Picker Controller deleagte

extension AppInfoViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        defer {
            picker.dismiss(animated: true, completion: nil)
        }
        guard let image = info[UIImagePickerControllerEditedImage] as? UIImage else { return }
        
        let fileName = UUID().uuidString
        let iconURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
        do {
            try UIImagePNGRepresentation(image)?.write(to: iconURL)
        } catch {
            return
        }
        
        self.app.setIcon(fileName: fileName)
        self.iconImageView.image = self.app.icon
        MaskedIconCache.shared.cacheIcons(for: [self.app])
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
