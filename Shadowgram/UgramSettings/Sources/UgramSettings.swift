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
    private var stringCache: [String: String] = [:]

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

    public func string(_ key: String) -> String? {
        self.lock.lock()
        defer {
            self.lock.unlock()
        }
        if let value = self.stringCache[key] {
            return value.isEmpty ? nil : value
        }
        let value = self.defaults.string(forKey: key) ?? ""
        self.stringCache[key] = value
        return value.isEmpty ? nil : value
    }

    public func setString(_ value: String?, for key: String) {
        let value = value ?? ""
        self.lock.lock()
        self.stringCache[key] = value
        self.lock.unlock()
        if value.isEmpty {
            self.defaults.removeObject(forKey: key)
        } else {
            self.defaults.set(value, forKey: key)
        }
    }

    public func int(_ key: String, default defaultValue: Int) -> Int {
        if let value = self.string(key), let parsed = Int(value) {
            return parsed
        }
        return defaultValue
    }

    public func setInt(_ value: Int, for key: String) {
        self.setString(String(value), for: key)
    }
}
