// MARK: Ugram - tell the sender that kept view-once media was opened.
import Foundation
import Postbox
import SwiftSignalKit
internal import TelegramApi
import MtProtoKit

/// Sends the "opened" receipt for a view-once message that Ugram kept, and marks it viewed locally.
/// The local copy stays; on the sender's side the media disappears as if it had been viewed.
public func ugramMarkSelfDestructViewed(account: Account, messageId: MessageId) -> Signal<Never, NoError> {
    let network = account.network
    let stateManager = account.stateManager
    let postbox = account.postbox
    return postbox.transaction { transaction -> Signal<Void, NoError> in
        let request: Signal<Void, NoError>
        if messageId.peerId.namespace == Namespaces.Peer.CloudUser || messageId.peerId.namespace == Namespaces.Peer.CloudGroup {
            request = network.request(Api.functions.messages.readMessageContents(id: [messageId.id]))
            |> map(Optional.init)
            |> `catch` { _ -> Signal<Api.messages.AffectedMessages?, NoError> in
                return .single(nil)
            }
            |> map { result -> Void in
                if let result {
                    switch result {
                    case let .affectedMessages(affectedMessagesData):
                        stateManager.addUpdateGroups([.updatePts(pts: affectedMessagesData.pts, ptsCount: affectedMessagesData.ptsCount)])
                    }
                }
            }
        } else if messageId.peerId.namespace == Namespaces.Peer.CloudChannel, let peer = transaction.getPeer(messageId.peerId), let inputChannel = apiInputChannel(peer) {
            request = network.request(Api.functions.channels.readMessageContents(channel: inputChannel, id: [messageId.id]))
            |> `catch` { _ -> Signal<Api.Bool, NoError> in
                return .single(.boolFalse)
            }
            |> map { _ -> Void in
            }
        } else {
            request = .single(Void())
        }
        return request
        |> mapToSignal { _ -> Signal<Void, NoError> in
            return postbox.transaction { transaction -> Void in
                transaction.updateMessage(messageId, update: { currentMessage in
                    guard let current = currentMessage.ugramSelfDestruct, !current.viewed else {
                        return .skip
                    }
                    var storeForwardInfo: StoreMessageForwardInfo?
                    if let forwardInfo = currentMessage.forwardInfo {
                        storeForwardInfo = StoreMessageForwardInfo(authorId: forwardInfo.author?.id, sourceId: forwardInfo.source?.id, sourceMessageId: forwardInfo.sourceMessageId, date: forwardInfo.date, authorSignature: forwardInfo.authorSignature, psaType: forwardInfo.psaType, flags: forwardInfo.flags)
                    }
                    var attributes = currentMessage.attributes.filter { !($0 is UgramSelfDestructMessageAttribute) }
                    attributes.append(UgramSelfDestructMessageAttribute(timeout: current.timeout, viewed: true))
                    return .update(StoreMessage(id: currentMessage.id, customStableId: nil, globallyUniqueId: currentMessage.globallyUniqueId, groupingKey: currentMessage.groupingKey, threadId: currentMessage.threadId, timestamp: currentMessage.timestamp, flags: StoreMessageFlags(currentMessage.flags), tags: currentMessage.tags, globalTags: currentMessage.globalTags, localTags: currentMessage.localTags, forwardInfo: storeForwardInfo, authorId: currentMessage.author?.id, text: currentMessage.text, attributes: attributes, media: currentMessage.media))
                })
            }
        }
    }
    |> switchToLatest
    |> ignoreValues
}
