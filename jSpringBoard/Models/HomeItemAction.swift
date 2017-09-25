//
//  HomeItemAction.swift
//  jSpringBoard
//
//  Created by Jota Melo on 26/07/17.
//  Copyright © 2017 jota. All rights reserved.
//

import UIKit

class HomeItemAction {
    var icon: UIImage
    var title: String
    var badge: Int?
    
    init(icon: UIImage, title: String, badge: Int?) {
        self.icon = icon
        self.title = title
        self.badge = badge
    }
}

class AppAction: HomeItemAction {
    var app: App
    
    init(app: App) {
        self.app = app
        super.init(icon: MaskedIconCache.shared.maskedIcon(for: app), title: app.name, badge: app.badge)
    }
}
