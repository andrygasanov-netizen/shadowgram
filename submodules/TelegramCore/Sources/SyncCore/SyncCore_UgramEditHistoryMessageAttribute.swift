// MARK: Ugram
import Foundation
import Postbox
import UgramSettings

/// Earlier versions of a message's text, oldest first, recorded on this device when an edit arrived.
public class UgramEditHistoryMessageAttribute: MessageAttribute {
    public struct Version: Equatable {
        public let text: String
        /// When this version was written (the message date, or the date of the edit that produced it).
        public let date: Int32

        public init(text: String, date: Int32) {
            self.text = text
            self.date = date
        }
    }

    public let versions: [Version]

    public init(versions: [Version]) {
        self.versions = versions
    }

    required public init(decoder: PostboxDecoder) {
        let texts = decoder.decodeStringArrayForKey("t")
        let dates = decoder.decodeInt32ArrayForKey("d")
        var versions: [Version] = []
        for i in 0 ..< min(texts.count, dates.count) {
            versions.append(Version(text: texts[i], date: dates[i]))
        }
        self.versions = versions
    }

    public func encode(_ encoder: PostboxEncoder) {
        encoder.encodeStringArray(self.versions.map(\.text), forKey: "t")
        encoder.encodeInt32Array(self.versions.map(\.date), forKey: "d")
    }
}

public extension Message {
    var ugramEditHistory: [UgramEditHistoryMessageAttribute.Version] {
        for attribute in self.attributes {
            if let attribute = attribute as? UgramEditHistoryMessageAttribute {
                return attribute.versions
            }
        }
        return []
    }
}

public extension EngineMessage {
    var ugramEditHistory: [UgramEditHistoryMessageAttribute.Version] {
        for attribute in self.attributes {
            if let attribute = attribute as? UgramEditHistoryMessageAttribute {
                return attribute.versions
            }
        }
        return []
    }
}

private let ugramEditHistoryLimit = 50

/// The edit history to store with an edited message: the previous one's history plus its text, when the text changed.
func ugramEditHistoryAttribute(previous: Message, updatedText: String) -> UgramEditHistoryMessageAttribute? {
    var versions = previous.ugramEditHistory
    if UgramSettings.shared.bool("ugramEditHistory", default: true), previous.text != updatedText, !previous.text.isEmpty {
        var previousDate = previous.timestamp
        for attribute in previous.attributes {
            if let attribute = attribute as? EditedMessageAttribute {
                previousDate = attribute.date
            }
        }
        versions.append(UgramEditHistoryMessageAttribute.Version(text: previous.text, date: previousDate))
        if versions.count > ugramEditHistoryLimit {
            versions.removeFirst(versions.count - ugramEditHistoryLimit)
        }
    }
    if versions.isEmpty {
        return nil
    }
    return UgramEditHistoryMessageAttribute(versions: versions)
}
