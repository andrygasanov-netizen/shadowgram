// MARK: Ugram - approves join requests to groups and channels the account administers, as soon as they arrive.
import Foundation
import Postbox
import SwiftSignalKit
internal import TelegramApi
import MtProtoKit
import UgramSettings

final class UgramJoinRequestApprover {
    static let shared = UgramJoinRequestApprover()

    private final class WeakAccount {
        weak var account: Account?

        init(_ account: Account) {
            self.account = account
        }
    }

    private let queue = Queue()
    private var accounts: [PeerId: WeakAccount] = [:]
    private var inFlight = Set<PeerId>()

    private init() {
    }

    static var isEnabled: Bool {
        return UgramSettings.shared.bool("ugramAutoApproveJoinRequests", default: false)
    }

    func register(account: Account) {
        let accountPeerId = account.peerId
        self.queue.async {
            self.accounts[accountPeerId] = WeakAccount(account)
        }
    }

    /// Called from the update interpreter when a chat reports pending join requests.
    func requestsPending(accountPeerId: PeerId, peerId: PeerId) {
        self.queue.async {
            guard let account = self.accounts[accountPeerId]?.account, !self.inFlight.contains(peerId) else {
                return
            }
            self.inFlight.insert(peerId)
            let signal: Signal<Never, NoError> = account.postbox.transaction { transaction -> Api.InputPeer? in
                return transaction.getPeer(peerId).flatMap { apiInputPeer($0) }
            }
            |> mapToSignal { inputPeer -> Signal<Never, NoError> in
                guard let inputPeer else {
                    return .complete()
                }
                // flags: 1 << 0 approves all pending requests.
                return account.network.request(Api.functions.messages.hideAllChatJoinRequests(flags: 1 << 0, peer: inputPeer, link: nil))
                |> `catch` { _ -> Signal<Api.Updates, NoError> in
                    return .complete()
                }
                |> mapToSignal { updates -> Signal<Never, NoError> in
                    account.stateManager.addUpdates(updates)
                    return .complete()
                }
            }
            let _ = (signal |> deliverOn(self.queue)).start(completed: {
                self.inFlight.remove(peerId)
            })
        }
    }
}
