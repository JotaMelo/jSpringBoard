//
//  HomeItem.swift
//  jSpringBoard
//
//  Created by Jota Melo on 14/06/17.
//  Copyright © 2017 jota. All rights reserved.
//

import Foundation

enum HomeItemType: Int {
    case app
    case folder
}

protocol HomeItem: class {
    var name: String { get set }
    var badge: Int? { get }
    var isShareable: Bool { get }
    
    func dictionaryRepresentation() -> [String: Any]
}
