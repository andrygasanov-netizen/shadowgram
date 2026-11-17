// MARK: Ugram
import Foundation
import Postbox

/// Marks view-once / self-destructing media that Ugram stored as regular media.
/// `viewed` is set once the user told the sender it was opened.
public class UgramSelfDestructMessageAttribute: MessageAttribute {
    public let timeout: Int32
    public let viewed: Bool

    public init(timeout: Int32, viewed: Bool) {
        self.timeout = timeout
        self.viewed = viewed
    }

    required public init(decoder: PostboxDecoder) {
        self.timeout = decoder.decodeInt32ForKey("t", orElse: 0)
        self.viewed = decoder.decodeInt32ForKey("v", orElse: 0) != 0
    }

    public func encode(_ encoder: PostboxEncoder) {
        encoder.encodeInt32(self.timeout, forKey: "t")
        encoder.encodeInt32(self.viewed ? 1 : 0, forKey: "v")
    }
}

public extension Message {
    var ugramSelfDestruct: UgramSelfDestructMessageAttribute? {
        for attribute in self.attributes {
            if let attribute = attribute as? UgramSelfDestructMessageAttribute {
                return attribute
            }
        }
        return nil
    }
}

public extension EngineMessage {
    var ugramSelfDestruct: UgramSelfDestructMessageAttribute? {
        for attribute in self.attributes {
            if let attribute = attribute as? UgramSelfDestructMessageAttribute {
                return attribute
            }
        }
        return nil
    }
}
