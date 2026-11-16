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
    case pages
    case all
}

private enum UgramBoolSetting: String {
    case ghostMode
}

private typealias UgramEntry = SGItemListUIEntry<UgramSection, UgramBoolSetting, AnyHashable, AnyHashable, UgramSettingsPage, AnyHashable>

private let ghostKeys = ["ugramNoReadReceipts", "ugramNoTyping", "ugramHideOnline"]

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
    entries.append(.toggle(id: id.count, section: .quick, settingName: .ghostMode, value: isGhostModeOn(), text: t("Режим призрака 👻", "Ghost mode 👻"), enabled: true))
    entries.append(.notice(id: id.count, section: .quick, text: t("Одним переключателем: не отправлять «прочитано», «печатает…» и «в сети». По отдельности — в разделе «Режим призрака».", "One switch for no read receipts, no typing and no online status. Separately: in the \"Ghost mode\" section.")))

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
    // Pages change the ghost switches too; refresh the quick toggle when coming back.
    controller.didAppear = { _ in
        refresh.set(true)
    }
    return controller
}
