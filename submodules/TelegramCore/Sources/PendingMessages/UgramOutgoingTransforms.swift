// MARK: Ugram - changes applied to outgoing text messages: auto-postfix, text style, heart effect, auto-sticker.
import Foundation
import Postbox
import UgramSettings

// The free ❤️ message effect.
private let ugramHeartEffectId: Int64 = 5159385139981059251

private func ugramTextStyleEntityType(_ value: String?) -> MessageTextEntityType? {
    switch value ?? "" {
    case "bold":
        return .Bold
    case "italic":
        return .Italic
    case "underline":
        return .Underline
    case "strikethrough":
        return .Strikethrough
    case "monospace":
        return .Code
    case "spoiler":
        return .Spoiler
    default:
        return nil
    }
}

func ugramTransformOutgoingMessages(transaction: Transaction, accountPeerId: PeerId, peerId: PeerId, messages: [(Bool, EnqueueMessage)]) -> [(Bool, EnqueueMessage)] {
    let settings = UgramSettings.shared
    let postfix = settings.string("ugramAutoPostfix")?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let styleType = ugramTextStyleEntityType(settings.string("ugramTextStyle"))
    let heartEffect = settings.bool("ugramHeartEffect", default: false)
    let autoSticker = settings.bool("ugramAutoSticker", default: false)

    if postfix.isEmpty && styleType == nil && !heartEffect && !autoSticker {
        return messages
    }
    if peerId.namespace == Namespaces.Peer.SecretChat {
        return messages
    }
    // Message effects only work in one-to-one chats.
    let canUseEffect = peerId.namespace == Namespaces.Peer.CloudUser && peerId != accountPeerId

    var result: [(Bool, EnqueueMessage)] = []
    var stickerThreadId: Int64?
    var sentPlainText = false
    var blocksSticker = false

    for (transformedMedia, message) in messages {
        guard case let .message(text, attributes, inlineStickers, mediaReference, threadId, replyToMessageId, replyToStoryId, localGroupingKey, correlationId, bubbleUpEmojiOrStickersets) = message, mediaReference == nil, !text.isEmpty, !text.hasPrefix("/") else {
            result.append((transformedMedia, message))
            continue
        }

        var updatedText = text
        var updatedAttributes = attributes
        if !postfix.isEmpty {
            updatedText += "\n" + postfix
        }
        if let styleType {
            var entities: [MessageTextEntity] = []
            for attribute in updatedAttributes {
                if let attribute = attribute as? TextEntitiesMessageAttribute {
                    entities.append(contentsOf: attribute.entities)
                }
            }
            updatedAttributes.removeAll(where: { $0 is TextEntitiesMessageAttribute })
            entities.insert(MessageTextEntity(range: 0 ..< (updatedText as NSString).length, type: styleType), at: 0)
            updatedAttributes.append(TextEntitiesMessageAttribute(entities: entities))
        }
        if heartEffect && canUseEffect && !updatedAttributes.contains(where: { $0 is EffectMessageAttribute }) {
            updatedAttributes.append(EffectMessageAttribute(id: ugramHeartEffectId))
        }
        for attribute in updatedAttributes {
            // A scheduled or paid message must not get an extra sticker sent right away or for stars.
            if attribute is OutgoingScheduleInfoMessageAttribute || attribute is PaidStarsMessageAttribute {
                blocksSticker = true
            }
        }

        result.append((transformedMedia, .message(text: updatedText, attributes: updatedAttributes, inlineStickers: inlineStickers, mediaReference: nil, threadId: threadId, replyToMessageId: replyToMessageId, replyToStoryId: replyToStoryId, localGroupingKey: localGroupingKey, correlationId: correlationId, bubbleUpEmojiOrStickersets: bubbleUpEmojiOrStickersets)))
        sentPlainText = true
        stickerThreadId = threadId
    }

    if autoSticker && sentPlainText && !blocksSticker {
        var stickerFile: TelegramMediaFile?
        for item in transaction.getOrderedListItems(collectionId: Namespaces.OrderedItemList.CloudRecentStickers) {
            if let contents = item.contents.get(RecentMediaItem.self) {
                stickerFile = contents.media._parse()
                break
            }
        }
        if let stickerFile {
            result.append((false, .message(text: "", attributes: [], inlineStickers: [:], mediaReference: AnyMediaReference.standalone(media: stickerFile), threadId: stickerThreadId, replyToMessageId: nil, replyToStoryId: nil, localGroupingKey: nil, correlationId: nil, bubbleUpEmojiOrStickersets: [])))
        }
    }

    return result
}
