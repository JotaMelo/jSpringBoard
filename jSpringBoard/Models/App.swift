//
//  App.swift
//  jSpringBoard
//
//  Created by Jota Melo on 12/08/17.
//  Copyright © 2017 jota. All rights reserved.
//

import UIKit

enum AppType: Int {
    case local
    case device
}

class App: HomeItem, Mappable {
    
    var name: String
    var bundleID: String
    var type: AppType
    var isShareable: Bool
    var badge: Int?
    var icon: UIImage? {
        if self.bundleID == "com.apple.mobilecal" {
            return CalendarIconManager.shared.icon
        }
        
        if self._icon != nil {
            return self._icon
        }
        
        if let iconName = self.iconName {
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(iconName)
            if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                self._icon = image
            }
        } else if self.type == .device {
            self._icon = DeviceApps.iconForApp(withBundleID: self.bundleID)
        }
        
        return self._icon
    }
    
    private var iconName: String?
    private var _icon: UIImage?
    
    required init(mapper: Mapper) {
        self.name = mapper.keyPath("name")
        self.bundleID = mapper.keyPath("bundleID")
        self.badge = mapper.keyPath("badge")
        self.isShareable = mapper.keyPath("shareable") ?? true
        self.type = mapper.keyPath("appType") ?? .local
        
        if let iconName: String = mapper.keyPath("icon") {
            self.iconName = iconName
            if self.type == .local {
                self._icon = UIImage(named: iconName)
            }
        }
    }
    
    func setIcon(fileName: String) {
        self.iconName = fileName
        self._icon = nil
    }
    
    func dictionaryRepresentation() -> [String: Any] {
        
        var dictionary = ["type": HomeItemType.app.rawValue, "name": self.name, "appType": self.type.rawValue, "bundleID": self.bundleID] as [String: Any]
        
        if let badge = self.badge {
            dictionary["badge"] = badge
        }
        
        if let iconName = self.iconName {
            dictionary["icon"] = iconName
        }
        
        return dictionary
    }
}

extension App: Equatable {
    static func ==(lhs: App, rhs: App) -> Bool {
        return lhs === rhs
    }
}

extension App: Hashable {
    var hashValue: Int {
        return self.bundleID.hashValue
    }
}

extension App: CustomDebugStringConvertible {
    var debugDescription: String {
        let memoryAddress = String(format: "%p", unsafeBitCast(self, to: Int.self))
        return "<App: \(memoryAddress)> - \(self.name)"
    }
}
