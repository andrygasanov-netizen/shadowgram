import Foundation

/// Ugram feature switches.
///
/// The interface is deliberately string-keyed and never changes when a setting is added:
/// almost every module of the app depends on this one, so a stable interface keeps a new
/// switch from invalidating the whole build. Keys and their defaults live at the call sites.
public final class UgramSettings {
    public static let shared = UgramSettings()

    private let defaults: UserDefaults = UserDefaults.standard
    private let lock = NSLock()
    private var cache: [String: Bool] = [:]

    private init() {
    }

    public func bool(_ key: String, default defaultValue: Bool) -> Bool {
        self.lock.lock()
        defer {
            self.lock.unlock()
        }
        if let value = self.cache[key] {
            return value
        }
        let value: Bool
        if let stored = self.defaults.object(forKey: key) as? Bool {
            value = stored
        } else {
            value = defaultValue
        }
        self.cache[key] = value
        return value
    }

    public func setBool(_ value: Bool, for key: String) {
        self.lock.lock()
        self.cache[key] = value
        self.lock.unlock()
        self.defaults.set(value, forKey: key)
    }
}
