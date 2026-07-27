//
//  Bundle+Acheron.swift
//  Acheron
//
//  Created by Joe Charlier on 7/28/26.
//  Copyright © 2026 Aepryus Software. All rights reserved.
//

import Foundation

public extension Bundle {
    // Search order for String.localized; main first so apps override their packages.
    static let localizations: [Bundle] = {
        var bundles: [Bundle] = [.main]
        let urls: [URL] = main.urls(forResourcesWithExtension: "bundle", subdirectory: nil) ?? []
        urls.sorted { $0.lastPathComponent < $1.lastPathComponent }.forEach {
            if let bundle = Bundle(url: $0) { bundles.append(bundle) }
        }
        return bundles
    }()

#if DEBUG
    // Keys with no entry in any bundle render as themselves, which reads as correct in English;
    // this is the only thing that makes them visible.  Reported once each.
    private static let unlocalizedLock: NSLock = NSLock()
    private static var unlocalized: Set<String> = []

    static func reportUnlocalized(key: String) {
        unlocalizedLock.lock()
        defer { unlocalizedLock.unlock() }
        guard !unlocalized.contains(key) else { return }
        unlocalized.insert(key)
        print("[Acheron] not localized: \"\(key)\"")
    }
#endif
}
