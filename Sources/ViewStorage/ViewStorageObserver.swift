//
//  ViewStorageObserver.swift
//  ViewStorage
//
//  Created by Taylor Lineman on 6/15/26.
//

import Foundation
import SwiftUI

/// Watches a single `UserDefaults` key with KVO and re-renders the owning view
/// when it changes — whether the change came from this process or from another
/// one (e.g. an app extension or widget writing into a shared suite).
///
/// It is an `ObservableObject` so SwiftUI can subscribe to it; the
/// `ViewStorageBox` holds it in a `@StateObject` so a single instance survives
/// across renders and owns the KVO registration's lifetime.
final class ViewStorageObserver: NSObject, ObservableObject, @unchecked Sendable {
    private weak var store: UserDefaults?
    private var key: String?

    /// Begin observing `key` on `store`, switching off any previous key. Cheap to call every render: it no-ops when already observing the same key.
    func observe(_ store: UserDefaults, key: String) {
        guard key != self.key || store !== self.store else { return }
        stop()
        store.addObserver(self, forKeyPath: key, options: [], context: nil)
        self.store = store
        self.key = key
    }

    /// Force a re-render (used for this view's own writes, so the UI updates immediately without depending on KVO delivery timing).
    @MainActor
    func markChanged() {
        self.objectWillChange.send()
    }

    private func stop() {
        defer { store = nil; key = nil }
        guard let store, let key else { return }
        store.removeObserver(self, forKeyPath: key)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        Task { @MainActor [weak self] in
            self?.markChanged()
        }
    }

    deinit { stop() }
}
