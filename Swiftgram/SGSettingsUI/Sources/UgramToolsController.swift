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
    case deletedMessages
    case ghost
    case quick
    case more
}

private enum UgramBoolSetting: String {
    case saveDeletedMessages
    case markDeletedMessages
    case keepSelfDestructingMedia
    case noReadReceipts
    case noTyping
    case hideOnline
    case storyStealthMode
    case hideStories
    case hideReactions
    case secondsInMessages
    case showProfileId
    case showRegDate
    case confirmCalls
    case uploadSpeedBoost
    case sendLargePhotos
    case contextShowJson
}

private enum UgramDisclosureLink: String {
    case swiftgramSettings
}

private typealias UgramEntry = SGItemListUIEntry<UgramSection, UgramBoolSetting, AnyHashable, AnyHashable, UgramDisclosureLink, AnyHashable>

private func ugramEntries(presentationData: PresentationData) -> [UgramEntry] {
    let isRussian = presentationData.strings.baseLanguageCode == "ru"
    let t: (String, String) -> String = { ru, en in
        return isRussian ? ru : en
    }
    let settings = SGSimpleSettings.shared
    let ugram = UgramSettings.shared

    var entries: [UgramEntry] = []
    let id = SGItemListCounter()

    entries.append(.header(id: id.count, section: .deletedMessages, text: t("УДАЛЁННЫЕ СООБЩЕНИЯ", "DELETED MESSAGES"), badge: nil))
    entries.append(.toggle(id: id.count, section: .deletedMessages, settingName: .saveDeletedMessages, value: ugram.bool("ugramSaveDeletedMessages", default: true), text: t("Сохранять удалённые сообщения", "Keep deleted messages"), enabled: true))
    entries.append(.toggle(id: id.count, section: .deletedMessages, settingName: .markDeletedMessages, value: ugram.bool("ugramMarkDeletedMessages", default: true), text: t("Помечать значком 🗑", "Mark with 🗑"), enabled: true))
    entries.append(.notice(id: id.count, section: .deletedMessages, text: t("Сообщения, которые собеседник удалил у всех, остаются в чате на этом устройстве и помечаются корзиной рядом со временем. Сохраняется только то, что уже было загружено в приложение. Секретные чаты и самоуничтожающиеся сообщения не сохраняются. Чтобы убрать такое сообщение, удалите его вручную.", "Messages deleted for everyone stay in the chat on this device and get a bin mark next to the time. Only messages that were already loaded by the app can be kept. Secret chats and self-destructing messages are not kept. Delete such a message manually to get rid of it.")))

    entries.append(.toggle(id: id.count, section: .deletedMessages, settingName: .keepSelfDestructingMedia, value: ugram.bool("ugramKeepSelfDestructingMedia", default: true), text: t("Сохранять исчезающие фото и видео", "Keep self-destructing photos and videos"), enabled: true))
    entries.append(.notice(id: id.count, section: .deletedMessages, text: t("Одноразовые и исчезающие фото, видео и голосовые приходят как обычные: их можно открывать сколько угодно раз и сохранять, а отправитель не видит, что вы их открыли. Действует только на медиа, полученные после включения.", "View-once and self-destructing photos, videos and voice messages arrive as regular media: open them any number of times and save them, and the sender does not see that you opened them. Applies only to media received after turning this on.")))

    entries.append(.header(id: id.count, section: .ghost, text: t("РЕЖИМ ПРИЗРАКА", "GHOST MODE"), badge: nil))
    entries.append(.toggle(id: id.count, section: .ghost, settingName: .noReadReceipts, value: ugram.bool("ugramNoReadReceipts", default: false), text: t("Не отправлять отметки о прочтении", "Don't send read receipts"), enabled: true))
    entries.append(.toggle(id: id.count, section: .ghost, settingName: .noTyping, value: ugram.bool("ugramNoTyping", default: false), text: t("Не показывать «печатает…»", "Don't send typing status"), enabled: true))
    entries.append(.toggle(id: id.count, section: .ghost, settingName: .hideOnline, value: ugram.bool("ugramHideOnline", default: false), text: t("Не показывать «в сети»", "Don't send online status"), enabled: true))
    entries.append(.toggle(id: id.count, section: .ghost, settingName: .storyStealthMode, value: settings.storyStealthMode, text: t("Скрытый просмотр историй", "Story stealth mode"), enabled: true))
    entries.append(.notice(id: id.count, section: .ghost, text: t("Пока отметки о прочтении выключены, чаты могут снова становиться непрочитанными после синхронизации. Отправка сообщения всё равно показывает вас в сети.", "While read receipts are off, chats may become unread again after a sync. Sending a message still makes you appear online.")))

    entries.append(.header(id: id.count, section: .quick, text: t("БЫСТРЫЕ НАСТРОЙКИ", "QUICK SETTINGS"), badge: nil))
    entries.append(.toggle(id: id.count, section: .quick, settingName: .hideStories, value: settings.hideStories, text: t("Скрыть истории", "Hide stories"), enabled: true))
    entries.append(.toggle(id: id.count, section: .quick, settingName: .hideReactions, value: settings.hideReactions, text: t("Скрыть реакции", "Hide reactions"), enabled: true))
    entries.append(.toggle(id: id.count, section: .quick, settingName: .secondsInMessages, value: settings.secondsInMessages, text: t("Секунды во времени сообщений", "Seconds in message time"), enabled: true))
    entries.append(.toggle(id: id.count, section: .quick, settingName: .showProfileId, value: settings.showProfileId, text: t("Показывать ID в профиле", "Show ID in profile"), enabled: true))
    entries.append(.toggle(id: id.count, section: .quick, settingName: .showRegDate, value: settings.showRegDate, text: t("Показывать дату регистрации", "Show registration date"), enabled: true))
    entries.append(.toggle(id: id.count, section: .quick, settingName: .confirmCalls, value: settings.confirmCalls, text: t("Подтверждать звонки", "Confirm calls"), enabled: true))
    entries.append(.toggle(id: id.count, section: .quick, settingName: .uploadSpeedBoost, value: settings.uploadSpeedBoost, text: t("Ускорение загрузки файлов", "Upload speed boost"), enabled: true))
    entries.append(.toggle(id: id.count, section: .quick, settingName: .sendLargePhotos, value: settings.sendLargePhotos, text: t("Отправлять большие фото", "Send large photos"), enabled: true))
    entries.append(.toggle(id: id.count, section: .quick, settingName: .contextShowJson, value: settings.contextShowJson, text: t("JSON сообщения в меню", "Message JSON in context menu"), enabled: true))

    entries.append(.header(id: id.count, section: .more, text: t("ЕЩЁ", "MORE"), badge: nil))
    entries.append(.disclosure(id: id.count, section: .more, link: .swiftgramSettings, text: t("Все настройки Swiftgram", "All Swiftgram settings")))
    entries.append(.notice(id: id.count, section: .more, text: t("Папки, вкладки, перевод, стикеры, контекстное меню и десятки других опций.", "Folders, tabs, translation, stickers, context menu and dozens of other options.")))

    return entries
}

public func ugramToolsController(context: AccountContext) -> ViewController {
    var pushControllerImpl: ((ViewController) -> Void)?

    let arguments = SGItemListArguments<UgramBoolSetting, AnyHashable, AnyHashable, UgramDisclosureLink, AnyHashable>(
        context: context,
        setBoolValue: { setting, value in
            let settings = SGSimpleSettings.shared
            let ugram = UgramSettings.shared
            switch setting {
            case .saveDeletedMessages:
                ugram.setBool(value, for: "ugramSaveDeletedMessages")
            case .markDeletedMessages:
                ugram.setBool(value, for: "ugramMarkDeletedMessages")
            case .keepSelfDestructingMedia:
                ugram.setBool(value, for: "ugramKeepSelfDestructingMedia")
            case .noReadReceipts:
                ugram.setBool(value, for: "ugramNoReadReceipts")
            case .noTyping:
                ugram.setBool(value, for: "ugramNoTyping")
            case .hideOnline:
                ugram.setBool(value, for: "ugramHideOnline")
            case .storyStealthMode:
                settings.storyStealthMode = value
            case .hideStories:
                settings.hideStories = value
            case .hideReactions:
                settings.hideReactions = value
            case .secondsInMessages:
                settings.secondsInMessages = value
            case .showProfileId:
                settings.showProfileId = value
            case .showRegDate:
                settings.showRegDate = value
            case .confirmCalls:
                settings.confirmCalls = value
            case .uploadSpeedBoost:
                settings.uploadSpeedBoost = value
            case .sendLargePhotos:
                settings.sendLargePhotos = value
            case .contextShowJson:
                settings.contextShowJson = value
            }
        },
        openDisclosureLink: { link in
            switch link {
            case .swiftgramSettings:
                pushControllerImpl?(sgSettingsController(context: context))
            }
        }
    )

    let signal = context.sharedContext.presentationData
    |> map { presentationData -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let entries = ugramEntries(presentationData: presentationData)

        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text("Ugram tools"), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))

        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: entries, style: .blocks, ensureVisibleItemTag: nil, initialScrollToItem: nil)

        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    pushControllerImpl = { [weak controller] c in
        (controller?.navigationController as? NavigationController)?.pushViewController(c)
    }
    return controller
}
