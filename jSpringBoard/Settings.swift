//
//  Settings.swift
//  jSpringBoard
//
//  Created by Jota Melo on 18/06/17.
//  Copyright © 2017 jota. All rights reserved.
//

import UIKit

class Settings {
    static let shared = Settings()
    
    var appsPerRow: Int = 4
    var appsPerRowOnFolder: Int = 3
    var appRows: Int
    var appRowsOnFolder: Int = 3
    
    var appsPerPage: Int { return self.appsPerRow * self.appRows }
    var appsPerPageOnFolder: Int { return self.appsPerRowOnFolder * self.appRowsOnFolder }
    
    var horizontalMargin: CGFloat
    var topMargin: CGFloat = 16
    var dockTopMargin: CGFloat = 4
    var lineSpacing: CGFloat = 0
    
    var cellSize: CGSize = CGSize(width: 79, height: 89)
    var folderCellSize: CGSize = CGSize(width: 13, height: 13)
    
    var homeButtonSize: CGFloat = 60
    var homeButtonMargin: CGFloat = 2
    var homeButtonInactiveAlpha: CGFloat = 0.4
    
    var isD22: Bool = false
    
    let wallpaperDefaultsKey = "wallpaperURL"
    var isOriginalWallpaper: Bool {
        return UserDefaults.standard.url(forKey: self.wallpaperDefaultsKey) == nil
    }
    var wallpaper: UIImage {
        if let wallpaperURL = UserDefaults.standard.url(forKey: self.wallpaperDefaultsKey), let data = try? Data(contentsOf: wallpaperURL), let image = UIImage(data: data) {
            return image
        }
        return #imageLiteral(resourceName: "bg")
    }
    
    var wallpaperView: UIView?
    
    init() {
        let screenSize = UIScreen.main.bounds.size
        
        if screenSize.height == 812 {
            self.appRows = 6
            self.horizontalMargin = 17.3
            self.topMargin = 60
            self.lineSpacing = 14.3
            self.isD22 = true
        } else if screenSize.height == 736 {
            self.appRows = 6
            self.horizontalMargin = 26
            self.topMargin = 26
            self.lineSpacing = 11
        } else if screenSize.height == 667 {
            self.appRows = 6
            self.horizontalMargin = 18
            self.cellSize.height = 88
        } else if screenSize.height == 568 {
            self.appRows = 5
            self.horizontalMargin = 9
            self.topMargin = 15
            self.cellSize = CGSize(width: 74, height: 88)
        } else {
            // the target is iOS 10 so it wouldn't run
            // on the 4S but it should work ok
            self.appRows = 4
            self.horizontalMargin = 9
            self.cellSize = CGSize(width: 74, height: 88)
        }
    }
    
    func snapshotOfWallpaper(at rect: CGRect) -> UIImage? {
        guard let imageView = self.wallpaperView else { return nil }
        
        let renderer = UIGraphicsImageRenderer(bounds: imageView.bounds)
        let snapshot = renderer.image { context in
            imageView.layer.render(in: context.cgContext)
        }
        
        UIGraphicsBeginImageContextWithOptions(rect.size, true, 0)
        snapshot.draw(in: rect)
        
        let cropRect = CGRect(x: rect.minX * snapshot.scale, y: rect.minY * snapshot.scale, width: rect.width * snapshot.scale, height: rect.height * snapshot.scale)
        guard let cgImage = snapshot.cgImage?.cropping(to: cropRect) else { return nil }
        return UIImage(cgImage: cgImage, scale: snapshot.scale, orientation: .up)
    }
}
