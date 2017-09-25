//
//  Mappable.swift
//  jMusic
//
//  Created by Jota Melo on 29/01/17.
//  Copyright © 2017 Jota. All rights reserved.
//

import Foundation

public protocol Mappable {
    
    init(dictionary: [String: Any])
    init(mapper: Mapper)
}

extension Mappable {
    
    init(dictionary: [String: Any]) {
        
        let mapper = Mapper(dictionary: dictionary)
        self.init(mapper: mapper)
    }
}

public class Mapper {
    
    private(set) var dictionary: [String: Any]
    var dateFormat = "yyyy/MM/dd"
    
    init(dictionary: [String: Any]) {
        self.dictionary = dictionary
    }
}

// MARK: - Optional mappers

extension Mapper {
    
    func map(_ value: Any?) -> String? {
        
        if let value = value as? String {
            return value
        } else if let value = value {
            return "\(value)"
        }
        
        return nil
    }
    
    func map(_ value: Any?) -> Float? {
        
        if let value = value as? Float {
            return value
        } else if let value = value as? Int {
            return Float(value)
        } else if let value = value as? Double {
            return Float(value)
        } else if let value = value as? String {
            return Float(value)
        }
        
        return nil
    }
    
    func map(_ value: Any?) -> Double? {
        
        if let value = value as? Double {
            return value
        } else if let value = value as? Int {
            return Double(value)
        } else if let value = value as? Float {
            return Double(value)
        } else if let value = value as? String {
            return Double(value)
        }
        
        return nil
    }
    
    func map(_ value: Any?) -> Int? {
        
        if let value = value as? Int {
            return value
        } else if let value = value as? Float {
            return Int(value)
        } else if let value = value as? Double {
            return Int(value)
        } else if let value = value as? String {
            return Int(value)
        }
        
        return nil
    }
    
    func map(_ value: Any?) -> Bool? {
        
        if let value = value as? Bool {
            return value
        } else if let value = value as? Int {
            return value > 0
        } else if let value = value as? String {
            switch value.lowercased() {
            case "true", "1":
                return true
            case "false", "0":
                return false
            default:
                return nil
            }
        }
        
        return nil
    }
    
    func map(_ value: Any?) -> Date? {
        
        if let value = value as? String {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = self.dateFormat
            return dateFormatter.date(from: value)
        } else if let value: TimeInterval = self.map(value) {
            return Date(timeIntervalSince1970: value)
        }
        
        return nil
    }
    
    func map(_ value: Any?) -> URL? {
        
        guard let value = value as? String else { return nil }
        return URL(string: value)
    }
    
    func map<T: RawRepresentable>(_ value: Any?) -> T? {
        
        if let value = value as? T.RawValue {
            return T(rawValue: value)
        }
        
        return nil
    }
    
    func map<T: Mappable>(_ value: Any?) -> T? {
        
        if let value = value as? [String: Any] {
            return T(dictionary: value)
        }
        
        return nil
    }
    
    // dictionaries, arrays & arrays of Mappable
    func map<T: Collection>(_ value: Any?) -> T? {
        
        if let elementType = T.Iterator.Element.self as? Mappable.Type {
            guard let value = value as? [[String: Any]] else { return nil }
            return value.flatMap({ (dictionary) -> T.Iterator.Element? in
                elementType.init(dictionary: dictionary) as? T.Iterator.Element
            }) as? T
        }
        return value as? T
    }
}

// MARK: - Optional Key Paths

extension Mapper {
    
    func keyPath(_ keyPath: String) -> String? {
        return self.map(self.dictionary[keyPath: keyPath])
    }
    
    func keyPath(_ keyPath: String) -> Float? {
        return self.map(self.dictionary[keyPath: keyPath])
    }
    
    func keyPath(_ keyPath: String) -> Double? {
        return self.map(self.dictionary[keyPath: keyPath])
    }
    
    func keyPath(_ keyPath: String) -> Int? {
        return self.map(self.dictionary[keyPath: keyPath])
    }
    
    func keyPath(_ keyPath: String) -> Bool? {
        return self.map(self.dictionary[keyPath: keyPath])
    }
    
    func keyPath(_ keyPath: String) -> Date? {
        return self.map(self.dictionary[keyPath: keyPath])
    }
    
    func keyPath(_ keyPath: String) -> URL? {
        return self.map(self.dictionary[keyPath: keyPath])
    }
    
    func keyPath<T: RawRepresentable>(_ keyPath: String) -> T? {
        return self.map(self.dictionary[keyPath: keyPath])
    }
    
    func keyPath<T: Mappable>(_ keyPath: String) -> T? {
        return self.map(self.dictionary[keyPath: keyPath])
    }
    
    func keyPath<T: Collection>(_ keyPath: String) -> T? {
        return self.map(self.dictionary[keyPath: keyPath])
    }
}

// MARK: - Non Optional Key Paths

extension Mapper {
    
    func keyPath(_ keyPath: String) -> String {
        return self.map(self.dictionary[keyPath: keyPath])!
    }
    
    func keyPath(_ keyPath: String) -> Float {
        return self.map(self.dictionary[keyPath: keyPath])!
    }
    
    func keyPath(_ keyPath: String) -> Double {
        return self.map(self.dictionary[keyPath: keyPath])!
    }
    
    func keyPath(_ keyPath: String) -> Int {
        return self.map(self.dictionary[keyPath: keyPath])!
    }
    
    func keyPath(_ keyPath: String) -> Bool {
        return self.map(self.dictionary[keyPath: keyPath])!
    }
    
    func keyPath(_ keyPath: String) -> Date {
        return self.map(self.dictionary[keyPath: keyPath])!
    }
    
    func keyPath(_ keyPath: String) -> URL {
        return self.map(self.dictionary[keyPath: keyPath])!
    }
    
    func keyPath<T: RawRepresentable>(_ keyPath: String) -> T {
        return self.map(self.dictionary[keyPath: keyPath])!
    }
    
    func keyPath<T: Mappable>(_ keyPath: String) -> T {
        return self.map(self.dictionary[keyPath: keyPath])!
    }
    
    func keyPath<T: Collection>(_ keyPath: String) -> T {
        return self.map(self.dictionary[keyPath: keyPath])!
    }
}

// MARK: - Dictionary Key Path extension
// https://oleb.net/blog/2017/01/dictionary-key-paths

fileprivate struct KeyPath {
    
    var segments: [String]
    
    var isEmpty: Bool { return segments.isEmpty }
    var path: String {
        return segments.joined(separator: ".")
    }
    
    /// Strips off the first segment and returns a pair
    /// consisting of the first segment and the remaining key path.
    /// Returns nil if the key path has no segments.
    func headAndTail() -> (head: String, tail: KeyPath)? {
        
        guard !isEmpty else { return nil }
        var tail = segments
        let head = tail.removeFirst()
        return (head, KeyPath(segments: tail))
    }
}

/// Initializes a KeyPath with a string of the form "this.is.a.keypath"
fileprivate extension KeyPath {
    
    init(_ string: String) {
        segments = string.components(separatedBy: ".")
    }
}

fileprivate protocol StringProtocol {
    init(string: String)
}

extension String: StringProtocol {
    init(string: String) {
        self = string
    }
}

fileprivate extension Dictionary where Key: StringProtocol {
    
    subscript(keyPath keyPath: String) -> Any? {
        
        get {
            if keyPath.isEmpty {
                return self
            }
            
            return self[keyPath: KeyPath(keyPath)]
        }
    }
    
    subscript(keyPath keyPath: KeyPath) -> Any? {
        
        get {
            switch keyPath.headAndTail() {
            case nil:
                // key path is empty.
                return nil
            case let (head, remainingKeyPath)? where remainingKeyPath.isEmpty:
                // Reached the end of the key path.
                let key = Key(string: head)
                return self[key]
            case let (head, remainingKeyPath)?:
                // Key path has a tail we need to traverse.
                let key = Key(string: head)
                switch self[key] {
                case let nestedDict as [Key: Any]:
                    // Next nest level is a dictionary.
                    // Start over with remaining key path.
                    return nestedDict[keyPath: remainingKeyPath]
                case let nestedArray as [Any]:
                    // Next nest level is an array
                    // Convert next key path segment to int
                    
                    guard let arrayIndex = Int(remainingKeyPath.segments[0]),
                        arrayIndex <= nestedArray.count - 1,
                        let value = nestedArray[arrayIndex] as? [Key: Any] else { return nil }
                    
                    var remainingKeyPath = remainingKeyPath
                    remainingKeyPath.segments.remove(at: 0)
                    return value[keyPath: remainingKeyPath]
                default:
                    // Next nest level isn't a dictionary.
                    // Invalid key path, abort.
                    return nil
                }
            }
        }
    }
}
