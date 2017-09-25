//
//  WallpaperViewController.swift
//  jSpringBoard
//
//  Created by Jota Melo on 31/08/17.
//  Copyright © 2017 jota. All rights reserved.
//

import UIKit

extension Notification.Name {
    static let wallpaperUpdated = Notification.Name("wallpaperUpdated")
}

class WallpaperViewController: UIViewController {

    @IBOutlet var homePlaceholderView: UIView!
    @IBOutlet var homeContainerView: UIView!
    @IBOutlet var stackView: UIStackView!
    
    var itemsManager: HomeItemsManager!
    private lazy var imagePickerController: UIImagePickerController = {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        return picker
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 11, *) {
            self.navigationItem.largeTitleDisplayMode = .never
        }

        self.homeContainerView.alpha = 0
        
        // this was making the view kinda jump before didAppear, which is weird
//        self.view.layoutIfNeeded()
//        self.homeContainerView.transform = CGAffineTransform.transform(rect: self.homeContainerView.frame, to: self.homePlaceholderView.frame)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if self.homeContainerView.transform == .identity {
            self.homeContainerView.transform = CGAffineTransform.transform(rect: self.homeContainerView.frame, to: self.homePlaceholderView.frame)
            UIView.animate(withDuration: 0.25) {
                self.homeContainerView.alpha = 1
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "home" {
            let viewController = segue.destination as! HomeViewController
            viewController.itemsManager = self.itemsManager
            viewController.readOnlyMode = true
        }
    }
    
    @IBAction func newWallpaperAction(_ sender: Any) {
        self.present(self.imagePickerController, animated: true, completion: nil)
    }
    
    @IBAction func resetWallpaper(_ sender: Any) {
        UserDefaults.standard.removeObject(forKey: Settings.shared.wallpaperDefaultsKey)
        NotificationCenter.default.post(name: .wallpaperUpdated, object: nil)
    }
}

// MARK: - Image Picker Controller deleagte

extension WallpaperViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        defer {
            picker.dismiss(animated: true, completion: nil)
        }
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else { return }
        
        let newURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(UUID().uuidString)
        do {
            try UIImagePNGRepresentation(image)?.write(to: newURL)
        } catch {
            return
        }
        
        if let previousURL = UserDefaults.standard.url(forKey: Settings.shared.wallpaperDefaultsKey) {
            try? FileManager.default.removeItem(at: previousURL)
        }
        
        UserDefaults.standard.set(newURL, forKey: Settings.shared.wallpaperDefaultsKey)
        NotificationCenter.default.post(name: .wallpaperUpdated, object: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
