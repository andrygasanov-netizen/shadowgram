// MARK: Ugram - "simple push": Telegram sends a PUT to an HTTPS URL when a new message arrives.
// Ugram points it at a private ntfy.sh topic; the ntfy app then shows a real push.
import Foundation
import SwiftSignalKit
internal import TelegramApi

public func ugramUpdateSimplePush(account: Account, url: String, register: Bool) -> Signal<Bool, NoError> {
    if register {
        return account.network.request(Api.functions.account.registerDevice(flags: 0, tokenType: 4, token: url, appSandbox: .boolFalse, secret: Buffer(), otherUids: []))
        |> map { _ -> Bool in
            return true
        }
        |> `catch` { _ -> Signal<Bool, NoError> in
            return .single(false)
        }
    } else {
        return account.network.request(Api.functions.account.unregisterDevice(tokenType: 4, token: url, otherUids: []))
        |> map { _ -> Bool in
            return true
        }
        |> `catch` { _ -> Signal<Bool, NoError> in
            return .single(false)
        }
    }
}
