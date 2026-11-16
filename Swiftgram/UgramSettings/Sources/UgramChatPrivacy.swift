import Foundation
import LocalAuthentication

/// Chats locked behind Face ID / Touch ID / the device passcode, and chats hidden from the chat list.
/// Peers are identified by the raw value of their id, scoped by the account's raw peer id.
public final class UgramChatPrivacy {
    public static let shared = UgramChatPrivacy()

    public enum Kind: String {
        case locked = "ugramLockedChats"
        case hidden = "ugramHiddenChats"
    }

    private let lock = NSLock()
    private var cache: [String: Set<Int64>] = [:]
    private var unlocked = Set<Int64>()

    private init() {
    }

    private func key(_ kind: Kind, accountId: Int64) -> String {
        return "\(kind.rawValue)_\(accountId)"
    }

    public func peers(_ kind: Kind, accountId: Int64) -> Set<Int64> {
        let key = self.key(kind, accountId: accountId)
        self.lock.lock()
        if let value = self.cache[key] {
            self.lock.unlock()
            return value
        }
        self.lock.unlock()
        let stored = UgramSettings.shared.string(key) ?? ""
        let value = Set(stored.split(separator: ",").compactMap { Int64($0) })
        self.lock.lock()
        self.cache[key] = value
        self.lock.unlock()
        return value
    }

    public func contains(_ kind: Kind, accountId: Int64, peerId: Int64) -> Bool {
        return self.peers(kind, accountId: accountId).contains(peerId)
    }

    public func set(_ kind: Kind, accountId: Int64, peerId: Int64, value: Bool) {
        var peers = self.peers(kind, accountId: accountId)
        if value {
            peers.insert(peerId)
        } else {
            peers.remove(peerId)
        }
        let key = self.key(kind, accountId: accountId)
        self.lock.lock()
        self.cache[key] = peers
        self.lock.unlock()
        UgramSettings.shared.setString(peers.map { String($0) }.joined(separator: ","), for: key)
        NotificationCenter.default.post(name: UgramChatPrivacy.didChange, object: nil)
    }

    public static let didChange = Notification.Name("UgramChatPrivacyDidChange")

    /// Whether opening this chat must be confirmed first.
    public func needsUnlock(accountId: Int64, peerId: Int64) -> Bool {
        guard self.contains(.locked, accountId: accountId, peerId: peerId) else {
            return false
        }
        self.lock.lock()
        defer {
            self.lock.unlock()
        }
        return !self.unlocked.contains(peerId)
    }

    /// Locks every unlocked chat again; called when the app goes to the background.
    public func relockAll() {
        self.lock.lock()
        self.unlocked.removeAll()
        self.lock.unlock()
    }

    /// Asks for Face ID / Touch ID, falling back to the device passcode. Calls back on the main queue.
    public func authenticate(reason: String, unlocking peerId: Int64? = nil, completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            // No passcode set on the device: nothing to check against.
            DispatchQueue.main.async {
                if let peerId {
                    self.markUnlocked(peerId)
                }
                completion(true)
            }
            return
        }
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, _ in
            DispatchQueue.main.async {
                if success, let peerId {
                    self.markUnlocked(peerId)
                }
                completion(success)
            }
        }
    }

    private func markUnlocked(_ peerId: Int64) {
        self.lock.lock()
        self.unlocked.insert(peerId)
        self.lock.unlock()
    }
}
