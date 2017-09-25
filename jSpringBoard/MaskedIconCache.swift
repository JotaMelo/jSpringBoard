//
//  MaskedIconCache.swift
//  jSpringBoard
//
//  Created by Jota Melo on 21/09/17.
//  Copyright © 2017 jota. All rights reserved.
//

import UIKit

class MaskedIconCache {
    static let shared = MaskedIconCache()
    
    private var cache: [App: UIImage] = [:]
    
    func cacheIcons(for apps: [App]) {
        DispatchQueue.global(qos: .utility).async {
            for app in apps {
                self.cacheIcon(for: app)
            }
        }
    }
    
    func maskedIcon(for app: App) -> UIImage {
        if let icon = self.cache[app] {
            return icon
        } else {
            return self.cacheIcon(for: app)
        }
    }
    
    @discardableResult
    private func cacheIcon(for app: App) -> UIImage {
        let maskedIcon = self.mask(image: app.icon ?? #imageLiteral(resourceName: "default-icon"), with: #imageLiteral(resourceName: "AppIconMask"))
        self.cache[app] = maskedIcon
        return maskedIcon
    }
    
    private func mask(image: UIImage, with mask: UIImage) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(image.size, false, 0)
        let context = UIGraphicsGetCurrentContext()!
        
        context.translateBy(x: 0, y: image.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        
        let rect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        context.clip(to: rect, mask: mask.cgImage!)
        context.draw(image.cgImage!, in: rect)
        
        let maskedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return maskedImage
    }
}

