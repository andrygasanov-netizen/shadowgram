// MARK: Ugram - folders with the groups and channels the account owns or administers.
import Foundation
import Postbox
import SwiftSignalKit
import UgramSettings

public struct UgramAdminFoldersResult {
    public let groups: Int
    public let channels: Int
    /// False when a folder was needed but the folder limit was reached.
    public let createdAll: Bool
}

private enum UgramAdminFolderKind {
    case groups
    case channels
}

private func ugramAdminKind(_ peer: Peer) -> UgramAdminFolderKind? {
    if let channel = peer as? TelegramChannel {
        guard channel.flags.contains(.isCreator) || channel.adminRights != nil else {
            return nil
        }
        if case .broadcast = channel.info {
            return .channels
        }
        return .groups
    }
    if let group = peer as? TelegramGroup {
        switch group.role {
        case .creator, .admin:
            return .groups
        case .member:
            return nil
        }
    }
    return nil
}

public func ugramUpdateAdminFolders(account: Account, groupsTitle: String, channelsTitle: String) -> Signal<UgramAdminFoldersResult, NoError> {
    let accountPeerId = account.peerId
    return account.postbox.transaction { transaction -> UgramAdminFoldersResult in
        let isPremium = transaction.getPeer(accountPeerId)?.isPremium ?? false
        let appConfiguration = transaction.getPreferencesEntry(key: PreferencesKeys.appConfiguration)?.get(AppConfiguration.self) ?? .defaultValue
        let limits = UserLimitsConfiguration(appConfiguration: appConfiguration, isPremium: isPremium)
        let maxPeers = Int(limits.maxFolderChatsCount)

        var groups: [PeerId] = []
        var channels: [PeerId] = []
        for groupId in [PeerGroupId.root, Namespaces.PeerGroup.archive] {
            for peer in transaction.getChatListPeers(groupId: groupId, filterPredicate: nil, additionalFilter: nil) {
                switch ugramAdminKind(peer) {
                case .groups:
                    if !groups.contains(peer.id) {
                        groups.append(peer.id)
                    }
                case .channels:
                    if !channels.contains(peer.id) {
                        channels.append(peer.id)
                    }
                case .none:
                    break
                }
            }
        }

        var createdAll = true
        let groupsKey = "ugramAdminFolderGroups_\(accountPeerId.toInt64())"
        let channelsKey = "ugramAdminFolderChannels_\(accountPeerId.toInt64())"
        var storedIds: [String: Int32] = [:]

        _internal_updateChatListFiltersInteractively(transaction: transaction, { filters in
            var filters = filters
            for (key, title, peerIds) in [(groupsKey, groupsTitle, groups), (channelsKey, channelsTitle, channels)] {
                let existingId = Int32(UgramSettings.shared.int(key, default: -1))
                let existingIndex = filters.firstIndex(where: { $0.id == existingId && existingId > 1 })
                if peerIds.isEmpty {
                    if let existingIndex {
                        filters.remove(at: existingIndex)
                    }
                    storedIds[key] = -1
                    continue
                }
                var includePeers = ChatListFilterIncludePeers()
                includePeers.setPeers(Array(peerIds.prefix(maxPeers)))
                let data = ChatListFilterData(isShared: false, hasSharedLinks: false, categories: [], excludeMuted: false, excludeRead: false, excludeArchived: false, includePeers: includePeers, excludePeers: [], color: nil)
                let folderTitle = ChatFolderTitle(text: title, entities: [], enableAnimations: true)
                if let existingIndex, case let .filter(id, _, emoticon, _) = filters[existingIndex] {
                    filters[existingIndex] = .filter(id: id, title: folderTitle, emoticon: emoticon, data: data)
                    storedIds[key] = id
                } else {
                    let folderCount = filters.filter { if case .filter = $0 { return true } else { return false } }.count
                    if folderCount >= Int(limits.maxFoldersCount) {
                        createdAll = false
                        continue
                    }
                    let id = _internal_generateNewChatListFilterId(filters: filters)
                    filters.append(.filter(id: id, title: folderTitle, emoticon: nil, data: data))
                    storedIds[key] = id
                }
            }
            return filters
        })
        for (key, id) in storedIds {
            UgramSettings.shared.setInt(Int(id), for: key)
        }
        return UgramAdminFoldersResult(groups: groups.count, channels: channels.count, createdAll: createdAll)
    }
}
