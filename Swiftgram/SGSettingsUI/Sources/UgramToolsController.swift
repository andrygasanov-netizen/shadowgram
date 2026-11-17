// MARK: Ugram
import SGSimpleSettings
import UgramSettings
import SGItemListUI

import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import AccountContext

private enum UgramSection: Int32, SGItemListSection {
    case quick
    case privacy
    case pages
    case all
}

private enum UgramBoolSetting: String {
    case ghostMode
}

private typealias UgramEntry = SGItemListUIEntry<UgramSection, UgramBoolSetting, AnyHashable, AnyHashable, UgramSettingsPage, AnyHashable>

private let ghostKeys = ["ugramNoReadReceipts", "ugramNoTyping", "ugramHideOnline"]

// MARK: Ugram - Telegram-settings-style icons for the hub rows.
private let ugramGhostIcon = renderSettingsIcon(name: "Item List/Icons/Privacy", backgroundColors: [UIColor(rgb: 0x5856D6)])
private let ugramChatsIcon = renderSettingsIcon(name: "Item List/Icons/Group", backgroundColors: [UIColor(rgb: 0x007AFF)])
private let ugramMessagesIcon = renderSettingsIcon(name: "Item List/Icons/Effect", backgroundColors: [UIColor(rgb: 0xAF52DE)])
private let ugramMediaIcon = renderSettingsIcon(name: "Item List/Icons/Photo", backgroundColors: [UIColor(rgb: 0xFF9500)])

private func ugramPageIcon(_ page: UgramSettingsPage) -> UIImage? {
    switch page {
    case .basic:
        return PresentationResourcesSettings.stars
    case .chats:
        return ugramChatsIcon
    case .ghost:
        return ugramGhostIcon
    case .interface:
        return PresentationResourcesSettings.appearance
    case .messages:
        return ugramMessagesIcon
    case .media:
        return ugramMediaIcon
    case .calls:
        return PresentationResourcesSettings.recentCalls
    case .all:
        return PresentationResourcesSettings.ugram
    }
}

private func isGhostModeOn() -> Bool {
    let ugram = UgramSettings.shared
    return ghostKeys.allSatisfy { ugram.bool($0, default: false) }
}

private func ugramEntries(presentationData: PresentationData) -> [UgramEntry] {
    let isRussian = presentationData.strings.baseLanguageCode == "ru"
    let t: (String, String) -> String = { ru, en in
        return isRussian ? ru : en
    }

    var entries: [UgramEntry] = []
    let id = SGItemListCounter()

    entries.append(.header(id: id.count, section: .quick, text: t("БЫСТРО", "QUICK"), badge: nil))
    entries.append(.disclosure(id: id.count, section: .quick, link: .basic, text: t("Основные настройки ⭐", "Essentials ⭐")))
    entries.append(.toggle(id: id.count, section: .quick, settingName: .ghostMode, value: isGhostModeOn(), text: t("Режим призрака 👻", "Ghost mode 👻"), enabled: true))
    entries.append(.notice(id: id.count, section: .quick, text: t("Одним переключателем: не отправлять «прочитано», «печатает…» и «в сети». По отдельности — в разделе «Режим призрака».", "One switch for no read receipts, no typing and no online status. Separately: in the \"Ghost mode\" section.")))

    entries.append(.header(id: id.count, section: .privacy, text: t("ПРИВАТНОСТЬ", "PRIVACY"), badge: nil))
    entries.append(.action(id: id.count, section: .privacy, actionType: AnyHashable("hiddenChats"), text: t("Скрытые чаты 🔒", "Hidden chats 🔒"), kind: .generic))
    entries.append(.notice(id: id.count, section: .privacy, text: t("Зажмите чат в списке, чтобы заблокировать его (вход по Face ID или коду телефона) или скрыть из списка чатов. Скрытые чаты открываются отсюда.", "Long-press a chat in the list to lock it (Face ID or device passcode) or hide it from the chat list. Hidden chats open from here.")))

    entries.append(.header(id: id.count, section: .pages, text: t("РАЗДЕЛЫ", "SECTIONS"), badge: nil))
    let pages: [UgramSettingsPage] = [.chats, .ghost, .interface, .messages, .media, .calls]
    for page in pages {
        entries.append(.disclosure(id: id.count, section: .pages, link: page, text: page.title(isRussian: isRussian)))
    }
    entries.append(.notice(id: id.count, section: .pages, text: t("Чаты — удалённые сообщения, список чатов, профили, меню сообщений. Интерфейс — вкладки, папки, истории, цвета. Сообщения — перевод, расшифровка голосовых, стикеры. Медиа — автозагрузка, качество фото, кружки.", "Chats: deleted messages, chat list, profiles, message menu. Interface: tabs, folders, stories, colors. Messages: translation, voice transcription, stickers. Media: auto-download, photo quality, video messages.")))

    entries.append(.disclosure(id: id.count, section: .all, link: .all, text: t("Все настройки и поиск", "All settings and search")))

    return entries
}

public func ugramToolsController(context: AccountContext) -> ViewController {
    var pushControllerImpl: ((ViewController) -> Void)?
    var presentControllerImpl: ((ViewController) -> Void)?
    var openChatImpl: ((EnginePeer) -> Void)?
    let refresh = ValuePromise(true, ignoreRepeated: false)

    let arguments = SGItemListArguments<UgramBoolSetting, AnyHashable, AnyHashable, UgramSettingsPage, AnyHashable>(
        context: context,
        setBoolValue: { setting, value in
            switch setting {
            case .ghostMode:
                for key in ghostKeys {
                    UgramSettings.shared.setBool(value, for: key)
                }
            }
            refresh.set(true)
        },
        openDisclosureLink: { page in
            pushControllerImpl?(sgSettingsController(context: context, page: page))
        },
        action: { actionType in
            guard actionType == AnyHashable("hiddenChats") else {
                return
            }
            let presentationData = context.sharedContext.currentPresentationData.with { $0 }
            let isRussian = presentationData.strings.baseLanguageCode == "ru"
            UgramChatPrivacy.shared.authenticate(reason: isRussian ? "Показать скрытые чаты" : "Show hidden chats", completion: { success in
                guard success else {
                    return
                }
                let ids = UgramChatPrivacy.shared.peers(.hidden, accountId: context.account.peerId.toInt64()).map { EnginePeer.Id($0) }
                let _ = (context.engine.data.get(EngineDataMap(ids.map { TelegramEngine.EngineData.Item.Peer.Peer(id: $0) }))
                |> deliverOnMainQueue).startStandalone(next: { peerMap in
                    let peers = ids.compactMap { peerMap[$0] ?? nil }.sorted { $0.debugDisplayTitle.lowercased() < $1.debugDisplayTitle.lowercased() }
                    let actionSheet = ActionSheetController(presentationData: presentationData)
                    var items: [ActionSheetItem] = []
                    if peers.isEmpty {
                        items.append(ActionSheetTextItem(title: isRussian ? "Скрытых чатов нет. Зажмите чат в списке и выберите «Скрыть чат»." : "No hidden chats. Long-press a chat in the list and choose \"Hide chat\"."))
                    }
                    for peer in peers {
                        items.append(ActionSheetButtonItem(title: peer.debugDisplayTitle, color: .accent, action: { [weak actionSheet] in
                            actionSheet?.dismissAnimated()
                            openChatImpl?(peer)
                        }))
                    }
                    actionSheet.setItemGroups([ActionSheetItemGroup(items: items), ActionSheetItemGroup(items: [
                        ActionSheetButtonItem(title: presentationData.strings.Common_Cancel, color: .accent, font: .bold, action: { [weak actionSheet] in
                            actionSheet?.dismissAnimated()
                        })
                    ])])
                    presentControllerImpl?(actionSheet)
                })
            })
        },
        toggleIcon: { _ in ugramGhostIcon },
        disclosureIcon: { page in ugramPageIcon(page) },
        actionIcon: { actionType in
            return actionType == AnyHashable("hiddenChats") ? PresentationResourcesSettings.faceId : nil
        }
    )

    let signal = combineLatest(context.sharedContext.presentationData, refresh.get())
    |> map { presentationData, _ -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let entries = ugramEntries(presentationData: presentationData)

        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text("Ugram Tools"), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))

        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: entries, style: .blocks, ensureVisibleItemTag: nil, initialScrollToItem: nil)

        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    pushControllerImpl = { [weak controller] c in
        (controller?.navigationController as? NavigationController)?.pushViewController(c)
    }
    presentControllerImpl = { [weak controller] c in
        controller?.present(c, in: .window(.root), with: ViewControllerPresentationArguments(presentationAnimation: .modalSheet))
    }
    openChatImpl = { [weak controller] peer in
        guard let navigationController = controller?.navigationController as? NavigationController else {
            return
        }
        context.sharedContext.navigateToChatController(NavigateToChatControllerParams(navigationController: navigationController, context: context, chatLocation: .peer(peer)))
    }
    // Pages change the ghost switches too; refresh the quick toggle when coming back.
    controller.didAppear = { _ in
        refresh.set(true)
    }
    return controller
}
