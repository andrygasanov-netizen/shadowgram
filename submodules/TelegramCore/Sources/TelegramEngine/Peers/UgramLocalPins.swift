// MARK: Ugram - pinned chats past the server limit, kept on this device only.
import Foundation
import Postbox
import UgramSettings

enum UgramLocalPins {
    static var isEnabled: Bool {
        return UgramSettings.shared.bool("ugramUnlimitedPins", default: false)
    }

    private static func key(accountPeerId: PeerId, groupId: PeerGroupId) -> String {
        return "ugramLocalPins_\(accountPeerId.toInt64())_\(groupId.rawValue)"
    }

    static func get(accountPeerId: PeerId, groupId: PeerGroupId) -> [PeerId] {
        guard let value = UgramSettings.shared.string(self.key(accountPeerId: accountPeerId, groupId: groupId)) else {
            return []
        }
        return value.split(separator: ",").compactMap { Int64($0) }.map { PeerId($0) }
    }

    static func set(_ peerIds: [PeerId], accountPeerId: PeerId, groupId: PeerGroupId) {
        let value = peerIds.map { String($0.toInt64()) }.joined(separator: ",")
        UgramSettings.shared.setString(value, for: self.key(accountPeerId: accountPeerId, groupId: groupId))
    }

    static func add(_ peerId: PeerId, accountPeerId: PeerId, groupId: PeerGroupId) {
        var peerIds = self.get(accountPeerId: accountPeerId, groupId: groupId)
        if !peerIds.contains(peerId) {
            peerIds.append(peerId)
            self.set(peerIds, accountPeerId: accountPeerId, groupId: groupId)
        }
    }

    static func remove(_ peerId: PeerId, accountPeerId: PeerId, groupId: PeerGroupId) {
        var peerIds = self.get(accountPeerId: accountPeerId, groupId: groupId)
        if let index = peerIds.firstIndex(of: peerId) {
            peerIds.remove(at: index)
            self.set(peerIds, accountPeerId: accountPeerId, groupId: groupId)
        }
    }

    /// The server's pins with this device's extra pins put back in their previous local positions.
    static func merge(serverItemIds: [PinnedItemId], previousLocalItemIds: [PinnedItemId], accountPeerId: PeerId, groupId: PeerGroupId) -> [PinnedItemId] {
        let localOnly = Set(self.get(accountPeerId: accountPeerId, groupId: groupId).map { PinnedItemId.peer($0) })
        if localOnly.isEmpty {
            return serverItemIds
        }
        var result = serverItemIds.filter { !localOnly.contains($0) }
        for (index, itemId) in previousLocalItemIds.enumerated() where localOnly.contains(itemId) && !result.contains(itemId) {
            result.insert(itemId, at: min(index, result.count))
        }
        return result
    }
}
