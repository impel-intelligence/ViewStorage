//
//  ViewStorable.swift
//  ViewStorage
//
//  Created by Taylor Lineman on 6/15/26.
//

import Foundation

/// A type that can be persisted to / read back from `UserDefaults` by
/// `@ViewStorage`.
///
/// Conformances are provided out of the box for the property-list-native types
/// (`Bool`, `Int`, `Double`, `Float`, `String`, `Data`, `Date`, `URL`). Two
/// protocol-extension defaults cover the common custom cases:
///
/// - **`RawRepresentable`** whose `RawValue` is itself a `ViewStorable`
///   (e.g. `enum Theme: String`) — stored as the raw value.
/// - **`Codable`** — stored as JSON `Data`.
///
/// So a custom type usually only needs an empty conformance:
///
///     enum Theme: String, ViewStorable { case light, dark }    // via RawRepresentable
///     struct Profile: Codable, ViewStorable { ... }            // via Codable (JSON)
///
/// > Note: If a type satisfies *both* the `RawRepresentable` and `Codable`
/// > defaults, the conformance is ambiguous — provide `read`/`write` explicitly
/// > to choose the representation.
public protocol ViewStorable {
    /// Reads the value stored at `key`, or `nil` if absent / undecodable.
    static func read(from store: UserDefaults, forKey key: String) -> Self?
    /// Writes `self` to `key`.
    func write(to store: UserDefaults, forKey key: String)
}

// MARK: Property-list-native conformances
extension Bool: ViewStorable {
    public static func read(from store: UserDefaults, forKey key: String) -> Bool? {
        store.object(forKey: key) as? Bool
    }
    
    public func write(to store: UserDefaults, forKey key: String) {
        store.set(self, forKey: key)
    }
}

extension Int: ViewStorable {
    public static func read(from store: UserDefaults, forKey key: String) -> Int? {
        store.object(forKey: key) as? Int
    }
    
    public func write(to store: UserDefaults, forKey key: String) {
        store.set(self, forKey: key)
    }
}

extension Double: ViewStorable {
    public static func read(from store: UserDefaults, forKey key: String) -> Double? {
        store.object(forKey: key) as? Double
    }
    
    public func write(to store: UserDefaults, forKey key: String) {
        store.set(self, forKey: key)
    }
}

extension Float: ViewStorable {
    public static func read(from store: UserDefaults, forKey key: String) -> Float? {
        store.object(forKey: key) as? Float
    }
    
    public func write(to store: UserDefaults, forKey key: String) {
        store.set(self, forKey: key)
    }
}

extension String: ViewStorable {
    public static func read(from store: UserDefaults, forKey key: String) -> String? {
        store.object(forKey: key) as? String
    }
    
    public func write(to store: UserDefaults, forKey key: String) {
        store.set(self, forKey: key)
    }
}

extension Data: ViewStorable {
    public static func read(from store: UserDefaults, forKey key: String) -> Data? {
        store.data(forKey: key)
    }
    
    public func write(to store: UserDefaults, forKey key: String) {
        store.set(self, forKey: key)
    }
}

extension Date: ViewStorable {
    public static func read(from store: UserDefaults, forKey key: String) -> Date? {
        store.object(forKey: key) as? Date
    }
    
    public func write(to store: UserDefaults, forKey key: String) {
        store.set(self, forKey: key)
    }
}

extension URL: ViewStorable {
    public static func read(from store: UserDefaults, forKey key: String) -> URL? {
        store.url(forKey: key)
    }
    
    public func write(to store: UserDefaults, forKey key: String) {
        store.set(self, forKey: key)
    }
}

extension Array: ViewStorable where Element: ViewStorable {
    public static func read(from store: UserDefaults, forKey key: String) -> [Element]? {
        store.array(forKey: key) as? [Element]
    }

    public func write(to store: UserDefaults, forKey key: String) {
        store.set(self, forKey: key)
    }
}

extension Dictionary: ViewStorable where Key == String, Value: ViewStorable {
    public static func read(from store: UserDefaults, forKey key: String) -> [String: Value]? {
        store.dictionary(forKey: key) as? [String: Value]
    }

    public func write(to store: UserDefaults, forKey key: String) {
        store.set(self, forKey: key)
    }
}


// MARK: RawRepresentable default, only when RawRepresentable == ViewStorable.
extension ViewStorable where Self: RawRepresentable, Self.RawValue: ViewStorable {
    public static func read(from store: UserDefaults, forKey key: String) -> Self? {
        RawValue.read(from: store, forKey: key).flatMap(Self.init(rawValue:))
    }
    
    public func write(to store: UserDefaults, forKey key: String) {
        rawValue.write(to: store, forKey: key)
    }
}

// MARK: Codable default (stored as JSON `Data`)
extension ViewStorable where Self: Codable {
    public static func read(from store: UserDefaults, forKey key: String) -> Self? {
        guard let data = store.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(Self.self, from: data)
    }
    
    public func write(to store: UserDefaults, forKey key: String) {
        guard let data = try? JSONEncoder().encode(self) else { return }
        store.set(data, forKey: key)
    }
}
