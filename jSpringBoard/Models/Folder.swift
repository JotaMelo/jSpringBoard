//
//  Folder.swift
//  jSpringBoard
//
//  Created by Jota Melo on 12/08/17.
//  Copyright © 2017 jota. All rights reserved.
//

import Foundation

class Folder: HomeItem, Mappable {
    
    var name: String
    var pages: [[App]]
    var badge: Int? {
        let totalBadge = self.pages.flatMap({ $0 }).reduce(0, { $0 + ($1.badge ?? 0) })
        if totalBadge == 0 {
            return nil
        } else {
            return totalBadge
        }
    }
    
    var isShareable = true
    var isNewFolder = false

    required init(mapper: Mapper) {
        self.name = mapper.keyPath("name")
        
        let pages: [JSONArray] = mapper.keyPath("apps")
        self.pages = pages.map { page in
            return page.map { App(dictionary: $0) }
        }
    }
    
    init(name: String, pages: [[App]]) {
        self.name = name
        self.pages = pages
    }
    
    func dictionaryRepresentation() -> [String : Any] {
        let apps = self.pages.map { page -> [[String : Any]] in
            return page.map { $0.dictionaryRepresentation() }
        }
        return ["type": HomeItemType.folder.rawValue, "name": self.name, "apps": apps]
    }
}

extension Folder: Equatable {
    static func ==(lhs: Folder, rhs: Folder) -> Bool {
        return lhs === rhs
    }
}

extension Folder: CustomDebugStringConvertible {
    var debugDescription: String {
        let memoryAddress = String(format: "%p", unsafeBitCast(self, to: Int.self))
        return "<Folder: \(memoryAddress)> - \(self.name)"
    }
}
