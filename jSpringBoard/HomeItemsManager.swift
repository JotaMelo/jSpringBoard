//
//  HomeItemsManager.swift
//  jSpringBoard
//
//  Created by Jota Melo on 12/08/17.
//  Copyright © 2017 jota. All rights reserved.
//

import Foundation

typealias JSONDictionary = [String: Any]
typealias JSONArray = [JSONDictionary]

enum AppLocationType {
    case main
    case dock
}

struct AppLocation {
    let type: AppLocationType
    let indexPath: IndexPath
}

class HomeItemsManager {
    
    private let itemsFileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("grid.json")
    
    var pages: [[HomeItem]] = []
    var dockItems: [HomeItem] = []
    lazy var appSuggestions: [App] = {
        var maxSuggestions = 8
        var suggestions = self.dockItems.flatMap { $0 as? App }
        
        var allApps = self.pages.flatMap({ $0 }).flatMap { $0 as? App }
        for i in 0..<maxSuggestions - suggestions.count {
            guard i < allApps.count else { break }
            suggestions.append(allApps[i])
        }
        
        return suggestions
    }()
    
    init() {
        if FileManager.default.fileExists(atPath: self.itemsFileURL.path) {
            // this is gonna be ugly and filled with force unwraps, look away kids
            let fileData = try! Data(contentsOf: self.itemsFileURL)
            let parsedData = (try! JSONSerialization.jsonObject(with: fileData, options: [])) as! JSONDictionary
            self.pages = (parsedData["pages"] as! [JSONArray]).map { self.homeItemsFrom(jsonArray: $0) }
            self.dockItems = self.homeItemsFrom(jsonArray: parsedData["dock"] as! JSONArray)
        } else {
            self.loadLocal()
            self.persistToDisk()
        }
    }
    
    private func homeItemsFrom(jsonArray: JSONArray) -> [HomeItem] {
        
        return jsonArray.flatMap { item -> HomeItem? in
            guard let typeID = item["type"] as? Int, let type = HomeItemType(rawValue: typeID) else { return nil }
            
            switch type {
            case .app:
                return App(dictionary: item)
            case .folder:
                var item = item
                let apps = item["apps"]!
                if let apps = apps as? [JSONDictionary] {
                    item["apps"] = apps.splitInChunks(ofSize: Settings.shared.appsPerPageOnFolder)
                }
                
                return Folder(dictionary: item)
            }
        }
    }
    
    private func search(_ query: String, in apps: [App]) -> [App] {
        
        let query = query.lowercased()
        return apps.filter { item -> Bool in
            let words = item.name.lowercased().components(separatedBy: " ")
            return words.filter({ $0.hasPrefix(query) }).count > 0
        }
    }
}

// MARK: - Public

extension HomeItemsManager {
    
    @discardableResult
    static func open(app: App) -> Bool {
        return DeviceApps.openApp(withBundleID: app.bundleID)
    }
    
    func loadLocal() {
        
        let parsedData: (_ fileName: String?) -> Any = { fileName in
            let url = Bundle.main.url(forResource: fileName, withExtension: "json")!
            let fileData = try! Data(contentsOf: url)
            let parsedData = try! JSONSerialization.jsonObject(with: fileData, options: [])
            return parsedData
        }
        
        let dockItems = parsedData("dock") as! JSONArray
        self.dockItems = self.homeItemsFrom(jsonArray: dockItems)
        
        let pages = parsedData("items") as! JSONArray
        self.pages = self.homeItemsFrom(jsonArray: pages).splitInChunks(ofSize: Settings.shared.appsPerPage)
    }
    
    func loadFromDevice() {
        
        let apps = DeviceApps.apps().flatMap { App(dictionary: $0) }
        self.dockItems = Array(apps[0...3])
        self.pages = Array(apps[4...]).splitInChunks(ofSize: Settings.shared.appsPerPage)
    }
    
    func persistToDisk() {
        
        let dockItems = self.dockItems.map { $0.dictionaryRepresentation() }
        let pages = self.pages.map { page -> [JSONDictionary] in
            return page.map { $0.dictionaryRepresentation() }
        }
        
        let dictionaryToPersist = ["pages": pages, "dock": dockItems] as JSONDictionary
        let jsonData = try! JSONSerialization.data(withJSONObject: dictionaryToPersist, options: [])
        try? jsonData.write(to: self.itemsFileURL)
    }
    
    func search(_ query: String) -> [SearchResult] {
        let flatItems = self.pages.flatMap({$0}) + self.dockItems
        
        // I could've used filter but then I'd have to as! the array to the right type
        let apps = flatItems.flatMap { $0 as? App }
        let folders = flatItems.flatMap { $0 as? Folder }
        
        let appResults = self.search(query, in: apps).map { SearchResult(app: $0, folder: nil) }
        let folderResults = folders.flatMap { item -> [SearchResult] in
            let apps = item.pages.flatMap({ $0 })
            return self.search(query, in: apps).map { SearchResult(app: $0, folder: item) }
        }
        
        return appResults + folderResults
    }
    
    func location(of app: App) -> AppLocation? {
        
        if let index = self.dockItems.index(where: { $0 === app }) {
            return AppLocation(type: .dock, indexPath: IndexPath(item: index, section: 0))
        }
        
        for (pageIndex, page) in self.pages.enumerated() {
            if let index = page.index(where: { $0 === app }) {
                return AppLocation(type: .main, indexPath: IndexPath(item: index, section: pageIndex))
            }
        }
        
        return nil
    }
    
    func add(app: App) {
        
        for (index, page) in self.pages.enumerated() {
            if page.count < Settings.shared.appsPerPage {
                self.pages[index].append(app)
                return
            }
        }
        
        self.pages.append([app])
    }
    
    func add(app: App, to folder: Folder) {
        
        for (index, page) in folder.pages.enumerated() {
            if page.count < Settings.shared.appsPerPageOnFolder {
                folder.pages[index].append(app)
                return
            }
        }
        
        folder.pages.append([app])
    }
    
    func remove(app: App, from folder: Folder) {
        
        for (index, page) in folder.pages.enumerated() {
            guard let appIndex = page.index(where: { $0 === app }) else { continue }
            folder.pages[index].remove(at: appIndex)
            if folder.pages[index].count == 0 {
                folder.pages.remove(at: index)
            }
            break
        }
        
        guard folder.pages.count == 0 else { return }
        for (index, page) in self.pages.enumerated() {
            if let folderIndex = page.index(where: { $0 === folder }) {
                self.pages[index].remove(at: folderIndex)
            }
        }
    }
}

// MARK: - Helpers

fileprivate extension Array {
    func splitInChunks(ofSize size: Int) -> [[Element]] {
        return stride(from: 0, to: self.count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, self.count)])
        }
    }
}
