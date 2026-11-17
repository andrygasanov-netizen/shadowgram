// MARK: Ugram
import Foundation
import Postbox

/// Marks a message that the server reported as deleted, but which Ugram kept in the local database.
public class UgramDeletedMessageAttribute: MessageAttribute {
    public let date: Int32

    public init(date: Int32) {
        self.date = date
    }

    required public init(decoder: PostboxDecoder) {
        self.date = decoder.decodeInt32ForKey("d", orElse: 0)
    }

    public func encode(_ encoder: PostboxEncoder) {
        encoder.encodeInt32(self.date, forKey: "d")
    }
}

public extension Message {
    var isUgramDeleted: Bool {
        for attribute in self.attributes {
            if attribute is UgramDeletedMessageAttribute {
                return true
            }
        }
        return false
    }
}

public extension EngineMessage {
    var isUgramDeleted: Bool {
        for attribute in self.attributes {
            if attribute is UgramDeletedMessageAttribute {
                return true
            }
        }
        return false
    }
}

/// Instead of removing the messages, tags the ones that are still stored with `UgramDeletedMessageAttribute`.
/// Returns the ids that must still be deleted the regular way (non-cloud namespaces).
func ugramMarkMessagesAsDeleted(transaction: Transaction, ids: [MessageId]) -> [MessageId] {
    var remainingIds: [MessageId] = []
    let date = Int32(CFAbsoluteTimeGetCurrent() + NSTimeIntervalSince1970)
    for id in ids {
        if id.namespace != Namespaces.Message.Cloud || id.peerId.namespace == Namespaces.Peer.SecretChat {
            remainingIds.append(id)
            continue
        }
        transaction.updateMessage(id, update: { currentMessage in
            if currentMessage.isUgramDeleted {
                return .skip
            }
            var storeForwardInfo: StoreMessageForwardInfo?
            if let forwardInfo = currentMessage.forwardInfo {
                storeForwardInfo = StoreMessageForwardInfo(authorId: forwardInfo.author?.id, sourceId: forwardInfo.source?.id, sourceMessageId: forwardInfo.sourceMessageId, date: forwardInfo.date, authorSignature: forwardInfo.authorSignature, psaType: forwardInfo.psaType, flags: forwardInfo.flags)
            }
            var attributes = currentMessage.attributes
            attributes.append(UgramDeletedMessageAttribute(date: date))
            return .update(StoreMessage(id: currentMessage.id, customStableId: nil, globallyUniqueId: currentMessage.globallyUniqueId, groupingKey: currentMessage.groupingKey, threadId: currentMessage.threadId, timestamp: currentMessage.timestamp, flags: StoreMessageFlags(currentMessage.flags), tags: currentMessage.tags, globalTags: currentMessage.globalTags, localTags: currentMessage.localTags, forwardInfo: storeForwardInfo, authorId: currentMessage.author?.id, text: currentMessage.text, attributes: attributes, media: currentMessage.media))
        })
    }
    return remainingIds
}
