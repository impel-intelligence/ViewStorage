// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI

/// Backing storage for `@ViewStorage`.
///
/// This is a `DynamicProperty`, so when the macro emits it as a plain stored
/// property of a view, SwiftUI discovers it via reflection, installs its
/// internal `@State`, and re-renders the view whenever `set(_:forKey:)` bumps
/// the version.
///
/// ## Why the `@State` lives here, not in the macro expansion
///
/// The `@State` version token is deliberately kept *inside* this library type
/// instead of having the `@ViewStorage` macro synthesize `@State` directly on
/// the view, because emitting `@State` from a macro crashed the compiler.
///
/// On the toolchain this was developed against (Apple Swift 6.3.3 /
/// Xcode 26.6), having an attached macro produce a peer/accessor declaration
/// marked `@State` (e.g. `@State private var fooVersion = 0`) passed type
/// checking but **crashed `swift-frontend` during IR generation**:
///
/// ```text
/// While emitting IR SIL function "...fooVersion...Sivg"
///   for getter for fooVersion
/// ...
/// swift::irgen::EnumPayload::store(...)   // recurses, then SIGSEGV
/// ```
///
/// The crash landed on whichever property carried the macro-synthesized
/// `@State`, and got worse when the generated name collided with the
/// `_<name>` / `$<name>` convention the compiler reserves for property-wrapper
/// backing and projection storage — the synthesis machinery then treated the
/// computed `storableValue` as a wrapped property and built a recursive type.
///
/// Wrapping the `@State` in this ordinary `DynamicProperty` struct sidesteps
/// the issue entirely: the macro only emits a plain stored property
/// (`private var fooStore = ViewStorageBox(...)`), which carries no attribute
/// for the compiler to mis-synthesize, while SwiftUI still installs the nested
/// `@State` via reflection.
public struct ViewStorageBox<Value>: DynamicProperty {
    @State private var version: Int = 0
    private let defaultValue: Value
    private let store: UserDefaults
    
    public init(default defaultValue: Value, store: UserDefaults = .standard) {
        self.defaultValue = defaultValue
        self.store = store
    }
    
    /// Reads the value at `key`. Touches `version` so SwiftUI records a
    /// dependency and re-renders the view after a later `set`.
    public func value(forKey key: String) -> Value {
        _ = version
        return store.object(forKey: key) as? Value ?? defaultValue
    }
    
    /// Writes `newValue` to `key` and triggers a re-render.
    public func set(_ newValue: Value, forKey key: String) {
        store.set(newValue, forKey: key)
        // Wrapping increment operator
        version &+= 1
    }
}

/// Mirrors `@AppStorage`, but derives its `UserDefaults` key dynamically from
/// another property on the enclosing view.
///
/// The final key is composed as `"<key>_<value at path>"`, so the same
/// declaration reads/writes a different slot as the path's value changes.
///
///     @ViewStorage("storableValue", path: \Self.id) var storableValue: String = "hi"
///
/// This expands into:
/// - a computed `storableValue` (get / nonmutating set) backed by `UserDefaults`,
/// - a hidden `ViewStorageBox` store that drives view updates,
/// - a `$storableValue` projected `Binding` for use with controls like `TextField`.
@attached(accessor)
@attached(peer, names: suffixed(Store), prefixed(`$`))
public macro ViewStorage<Root, Value: StringProtocol>(_ key: String, path: KeyPath<Root, Value>) = #externalMacro(module: "ViewStorageMacros", type: "ViewStorageMacro")
