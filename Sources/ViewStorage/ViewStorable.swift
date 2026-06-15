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
    /// A property-list-compatible representation of `self`.
    var plistRepresentable: Any { get }
    
    /// Initialize a copy of this `Self` using the property-list-compatible representation of a `Self`.
    init?(plistRepresentable: Any)
    
    /// Reads the value stored at `key`, or `nil` if absent / undecodable.
    static func read(from store: UserDefaults, forKey key: String) -> Self?
    /// Writes `self` to `key`.
    func write(to store: UserDefaults, forKey key: String)
}

extension ViewStorable {
    public static func read(from store: UserDefaults, forKey key: String) -> Self? {
        return store.object(forKey: key).flatMap({ Self.init(plistRepresentable: $0) })
    }
    
    public func write(to store: UserDefaults, forKey key: String) {
        store.set(plistRepresentable, forKey: key)
    }
}

// MARK: Property-list-native conformances
extension Bool: ViewStorable {
    public var plistRepresentable: Any { self }
    
    public init?(plistRepresentable: Any) {
        guard let value = plistRepresentable as? Bool else { return nil }
        self = value
    }
}

extension Int: ViewStorable {
    public var plistRepresentable: Any { self }
    
    public init?(plistRepresentable: Any) {
        guard let value = plistRepresentable as? Int else { return nil }
        self = value
    }
}

extension Double: ViewStorable {
    public var plistRepresentable: Any { self }
    
    public init?(plistRepresentable: Any) {
        guard let value = plistRepresentable as? Double else { return nil }
        self = value
    }
}

extension Float: ViewStorable {
    public var plistRepresentable: Any { self }
    
    public init?(plistRepresentable: Any) {
        guard let value = plistRepresentable as? Float else { return nil }
        self = value
    }
}

extension String: ViewStorable {
    public var plistRepresentable: Any { self }
    
    public init?(plistRepresentable: Any) {
        guard let value = plistRepresentable as? String else { return nil }
        self = value
    }
}

extension Data: ViewStorable {
    public var plistRepresentable: Any { self }
    
    public init?(plistRepresentable: Any) {
        guard let value = plistRepresentable as? Data else { return nil }
        self = value
    }
}

extension Date: ViewStorable {
    public var plistRepresentable: Any { self }
    
    public init?(plistRepresentable: Any) {
        guard let value = plistRepresentable as? Date else { return nil }
        self = value
    }
}

extension Array: ViewStorable where Element: ViewStorable {
    public var plistRepresentable: Any { map(\.plistRepresentable) }
    
    public init?(plistRepresentable: Any) {
        guard let objects = plistRepresentable as? [Any] else { return nil }
        var array: [Element] = []
        array.reserveCapacity(objects.count)
        for object in objects {
            guard let element = Element(plistRepresentable: object) else { return nil }
            array.append(element)
        }
        self = array
    }
}

extension Dictionary: ViewStorable where Key == String, Value: ViewStorable {
    public var plistRepresentable: Any { mapValues(\.plistRepresentable) }
    
    public init?(plistRepresentable: Any) {
        guard let objects = plistRepresentable as? [String: Any] else { return nil }
        var dictionary: [String: Value] = [:]
        for (key, value) in objects {
            guard let element = Value(plistRepresentable: value) else { return nil }
            dictionary[key] = element
        }
        self = dictionary
    }
}


//MARK: Non-native property list values
extension Set: ViewStorable where Element: ViewStorable {
    public var plistRepresentable: Any { map(\.plistRepresentable) }
    
    public init?(plistRepresentable: Any) {
        guard let objects = plistRepresentable as? [Any] else { return nil }
        var set: Set<Element> = []
        set.reserveCapacity(objects.count)
        for object in objects {
            guard let element = Element(plistRepresentable: object) else { return nil }
            set.insert(element)
        }
        self = set
    }
}

extension URL: ViewStorable {
    public var plistRepresentable: Any { self }
    
    public init?(plistRepresentable: Any) {
        guard let value = plistRepresentable as? String else { return nil }
        guard let url = URL(string: value) else { return nil }
        self = url
    }
}


// MARK: RawRepresentable default, only when RawRepresentable == ViewStorable.
extension ViewStorable where Self: RawRepresentable, Self.RawValue: ViewStorable {
    public var plistRepresentable: Any {
        rawValue.plistRepresentable
    }
    
    public init?(plistRepresentable: Any) {
        guard let value = RawValue(plistRepresentable: plistRepresentable) else { return nil }
        self.init(rawValue: value)
    }
}

// MARK: Codable default (stored as JSON `Data`)
extension ViewStorable where Self: Codable {
    public var propertyListValue: Any {
        (try? JSONEncoder().encode(self)) ?? Data()
    }
    
    public init?(propertyListValue: Any) {
        guard let data = propertyListValue as? Data else { return nil }
        guard let value = try? JSONDecoder().decode(Self.self, from: data) else { return nil }
        self = value
    }
}
