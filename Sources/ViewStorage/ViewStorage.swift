// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI
import Foundation

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
///
/// The stored property's type must conform to `ViewStorable`.
@attached(accessor)
@attached(peer, names: suffixed(Store), prefixed(`$`))
public macro ViewStorage<Root, Value: ViewStorable>(_ key: String, path: KeyPath<Root, Value>) = #externalMacro(module: "ViewStorageMacros", type: "ViewStorageMacro")
