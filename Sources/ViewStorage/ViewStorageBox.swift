//
//  ViewStorageBox.swift
//  ViewStorage
//
//  Created by Taylor Lineman on 6/15/26.
//

import Foundation
import SwiftUI

/// Backing storage for the`@ViewStorage` macro.
///
/// This is a `DynamicProperty`, so when the macro emits it as a plain stored
/// property of a view, SwiftUI discovers it via reflection, installs its
/// nested `@StateObject` observer, and re-renders the view when the watched
/// key changes.
///
/// ## Why the SwiftUI storage lives here, not in the macro expansion
///
/// The view-invalidation storage (now a `@StateObject` observer; previously a
/// `@State` token) is deliberately kept *inside* this library type instead of
/// having the `@ViewStorage` macro synthesize it directly on the view, because
/// emitting a SwiftUI storage attribute from a macro crashed the compiler.
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
/// SwiftUI attribute, and got worse when the generated name collided with the
/// `_<name>` / `$<name>` convention the compiler reserves for property-wrapper
/// backing and projection storage — the synthesis machinery then treated the
/// computed `storableValue` as a wrapped property and built a recursive type.
///
/// Wrapping that storage in this ordinary `DynamicProperty` struct sidesteps
/// the issue entirely: the macro only emits a plain stored property
/// (`private var fooStore = ViewStorageBox(...)`), which carries no attribute
/// for the compiler to mis-synthesize, while SwiftUI still installs the nested
/// storage via reflection.
///
/// > Note: KVO observation uses the composed key as a KVC key path, so a key
/// > whose dynamic component contains a `.` will not be observed correctly.
@MainActor
public struct ViewStorageBox<Value: ViewStorable>: DynamicProperty {
    @StateObject private var observer = ViewStorageObserver()
    private let defaultValue: Value
    private let store: UserDefaults
    
    public init(default defaultValue: Value, store: UserDefaults = .standard) {
        self.defaultValue = defaultValue
        self.store = store
    }
    
    /// Reads the value at `key`, (re)registering KVO so external changes to that
    /// key re-render the view.
    public func value(forKey key: String) -> Value {
        observer.observe(store, key: key)
        return Value.read(from: store, forKey: key) ?? defaultValue
    }
    
    /// Writes `newValue` to `key` and triggers an immediate re-render.
    public func set(_ newValue: Value, forKey key: String) {
        newValue.write(to: store, forKey: key)
        observer.markChanged()
    }
}
