// MARK: Swiftgram
import SGLogging
import SGSimpleSettings
import SGStrings
import SGAPIToken
import UgramSettings // MARK: Ugram
import PromptUI // MARK: Ugram

import SGItemListUI
import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramCore
import MtProtoKit
import MessageUI
import TelegramPresentationData
import TelegramUIPreferences
import ItemListUI
import PresentationDataUtils
import OverlayStatusController
import AccountContext
import AppBundle
import WebKit
import PeerNameColorScreen
import UndoUI


private enum SGControllerSection: Int32, SGItemListSection {
    case search
    case trending
    case content
    case tabs
    case folders
    case chatList
    case profiles
    case stories
    case translation
    case voiceMessages
    case calls
    case photo
    case stickers
    case videoNotes
    case contextMenu
    case accountColors
    case other
    // MARK: Ugram
    case ugramDeleted
    case ugramGhost
    case ugramMedia
    case ugramMessages
    case ugramAdmin
    case ugramChatList
    case ugramBasic
}

// MARK: Ugram - pages of Ugram tools; each shows a subset of the sections above.
public enum UgramSettingsPage: Int {
    case basic
    case chats
    case ghost
    case interface
    case messages
    case media
    case calls
    case all

    fileprivate var sections: Set<SGControllerSection>? {
        switch self {
        case .basic:
            return [.ugramBasic]
        case .chats:
            return [.ugramChatList, .ugramDeleted, .ugramAdmin, .chatList, .profiles, .contextMenu]
        case .ghost:
            return [.ugramGhost]
        case .interface:
            return [.trending, .tabs, .folders, .stories, .accountColors, .other]
        case .messages:
            return [.ugramMessages, .translation, .voiceMessages, .stickers]
        case .media:
            return [.ugramMedia, .photo, .videoNotes]
        case .calls:
            return [.calls]
        case .all:
            return nil
        }
    }

    public func title(isRussian: Bool) -> String {
        switch self {
        case .basic:
            return isRussian ? "Основные настройки" : "Essentials"
        case .chats:
            return isRussian ? "Чаты" : "Chats"
        case .ghost:
            return isRussian ? "Режим призрака" : "Ghost mode"
        case .interface:
            return isRussian ? "Интерфейс" : "Interface"
        case .messages:
            return isRussian ? "Сообщения и перевод" : "Messages & translation"
        case .media:
            return isRussian ? "Медиа и загрузки" : "Media & downloads"
        case .calls:
            return isRussian ? "Звонки" : "Calls"
        case .all:
            return isRussian ? "Все настройки" : "All settings"
        }
    }
}

private enum SGBoolSetting: String {
    case hidePhoneInSettings
    case showTabNames
    case showContactsTab
    case showCallsTab
    case wideTabBar
    case foldersAtBottom
    case startTelescopeWithRearCam
    case hideStories
    case uploadSpeedBoost
    case showProfileId
    case warnOnStoriesOpen
    case sendWithReturnKey
    case rememberLastFolder
    case sendLargePhotos
    case storyStealthMode
    case disableSwipeToRecordStory
    case disableDeleteChatSwipeOption
    case quickTranslateButton
    case hideReactions
    case showRepostToStory
    case contextShowSelectFromUser
    case contextShowSaveToCloud
    case contextShowHideForwardName
    case contextShowRestrict
    case contextShowReport
    case contextShowReply
    case contextShowPin
    case contextShowSaveMedia
    case contextShowMessageReplies
    case contextShowJson
    case disableScrollToNextChannel
    case disableScrollToNextTopic
    case disableChatSwipeOptions
    case disableGalleryCamera
    case disableGalleryCameraPreview
    case disableSendAsButton
    case disableSnapDeletionEffect
    case stickerTimestamp
    case hideRecordingButton
    case hideTabBar
    case showDC
    case showCreationDate
    case showRegDate
    case compactChatList
    case compactMessagePreview
    case compactFolderNames
    case allChatsHidden
    case defaultEmojisFirst
    case messageDoubleTapActionOutgoingEdit
    case wideChannelPosts
    case forceEmojiTab
    case forceBuiltInMic
    case secondsInMessages
    case hideChannelBottomButton
    case confirmCalls
    case swipeForVideoPIP
    case enableVoipTcp
    case nyStyleSnow
    case nyStyleLightning
    case tabBarSearchEnabled
    case videoControlsInFooter
    case combinedMediaViewer
    case hideAccountInNotifications
    // MARK: Ugram
    case ugramSaveDeletedMessages
    case ugramMarkDeletedMessages
    case ugramKeepSelfDestructingMedia
    case ugramNoReadReceipts
    case ugramNoTyping
    case ugramHideOnline
    case ugramDisableAutoDownload
    case ugramHeartEffect
    case ugramEditHistory
    case ugramAutoApproveJoinRequests
    case ugramAutoSticker
    case ugramUnlimitedPins
    case ugramBackgroundNotifications
    case ugramInstantPush
}

private enum SGOneFromManySetting: String {
    case nyStyle
    case bottomTabStyle
    case downloadSpeedBoost
    case allChatsTitleLengthOverride
//    case allChatsFolderPositionOverride
    case translationBackend
    case transcriptionBackend
    // MARK: Ugram
    case ugramTextStyle
    case ugramAutoPostfix
    case ugramAdminFolders
    case ugramUnreadReminder
    case ugramRecommended
    case ugramIslandBadge
    case ugramNtfySubscribe
}

// MARK: Ugram
private let ugramTextStyles: [(value: String, ru: String, en: String)] = [
    ("", "Без стиля", "No style"),
    ("bold", "Жирный", "Bold"),
    ("italic", "Курсив", "Italic"),
    ("underline", "Подчёркнутый", "Underline"),
    ("strikethrough", "Зачёркнутый", "Strikethrough"),
    ("monospace", "Моноширинный", "Monospace"),
    ("spoiler", "Скрытый (спойлер)", "Spoiler")
]

private let ugramReminderHours: [Int] = [0, 1, 3, 6, 12, 24]

// MARK: Ugram - instant notifications through a private ntfy.sh topic (Telegram "simple push").
private func ugramNtfyTopic() -> String {
    if let topic = UgramSettings.shared.string("ugramNtfyTopic"), !topic.isEmpty {
        return topic
    }
    let chars = Array("abcdefghijklmnopqrstuvwxyz0123456789")
    let topic = "ugram-" + String((0 ..< 24).map { _ in chars.randomElement()! })
    UgramSettings.shared.setString(topic, for: "ugramNtfyTopic")
    return topic
}

private func ugramNtfyPushURL(isRussian: Bool) -> String {
    let message = (isRussian ? "Новое сообщение" : "New message").addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
    return "https://ntfy.sh/\(ugramNtfyTopic())?title=Ugram&message=\(message)&filename=m.txt&click=ugram%3A%2F%2F&tags=speech_balloon"
}

private func ugramUpdateInstantPush(context: AccountContext, enabled: Bool, isRussian: Bool) {
    let newURL = ugramNtfyPushURL(isRussian: isRussian)
    let oldURL = UgramSettings.shared.string("ugramNtfyRegisteredURL") ?? ""
    let _ = (context.sharedContext.activeAccountContexts
    |> take(1)
    |> deliverOnMainQueue).startStandalone(next: { accounts in
        for (_, accountContext, _) in accounts.accounts {
            if !oldURL.isEmpty && (!enabled || oldURL != newURL) {
                let _ = ugramUpdateSimplePush(account: accountContext.account, url: oldURL, register: false).startStandalone()
            }
            if enabled {
                let _ = ugramUpdateSimplePush(account: accountContext.account, url: newURL, register: true).startStandalone()
            }
        }
    })
    UgramSettings.shared.setString(enabled ? newURL : "", for: "ugramNtfyRegisteredURL")
}

private func ugramOpenNtfy(context: AccountContext) {
    let topic = ugramNtfyTopic()
    UIPasteboard.general.string = topic
    guard let url = URL(string: "ntfy://ntfy.sh/\(topic)") else {
        return
    }
    UIApplication.shared.open(url, options: [:], completionHandler: { success in
        if !success {
            context.sharedContext.applicationBindings.openUrl("https://apps.apple.com/app/ntfy/id1625396347")
        }
    })
}

// MARK: Ugram - the badge drawn beside the Dynamic Island.
private let ugramIslandBadges: [(value: String, ru: String, en: String)] = [
    ("", "Зелёный", "Green"),
    ("UgramBlueAppBadge", "Синий", "Blue"),
    ("UgramPurpleAppBadge", "Фиолетовый", "Purple"),
    ("UgramOrangeAppBadge", "Оранжевый", "Orange"),
    ("UgramBlackAppBadge", "Чёрный", "Black"),
    ("hidden", "Скрыть", "Hidden"),
]

private func ugramIslandBadgeTitle(_ value: String, isRussian: Bool) -> String {
    for badge in ugramIslandBadges where badge.value == value {
        return isRussian ? badge.ru : badge.en
    }
    return isRussian ? "Зелёный" : "Green"
}

private func ugramReminderTitle(_ hours: Int, isRussian: Bool) -> String {
    if hours <= 0 {
        return isRussian ? "Отключено" : "Off"
    }
    if isRussian {
        let suffix: String
        switch hours {
        case 1, 21:
            suffix = "час"
        case 2, 3, 4, 22, 23, 24:
            suffix = "часа"
        default:
            suffix = "часов"
        }
        return "Через \(hours) \(suffix)"
    }
    return hours == 1 ? "After 1 hour" : "After \(hours) hours"
}

private func ugramTextStyleTitle(_ value: String, isRussian: Bool) -> String {
    for style in ugramTextStyles where style.value == value {
        return isRussian ? style.ru : style.en
    }
    return isRussian ? "Без стиля" : "No style"
}

private enum SGSliderSetting: String {
    case accountColorsSaturation
    case outgoingPhotoQuality
    case stickerSize
}

private enum SGDisclosureLink: String {
    case contentSettings
    case languageSettings
}

private struct PeerNameColorScreenState: Equatable {
    var updatedNameColor: PeerNameColor?
    var updatedBackgroundEmojiId: Int64?
}

private struct SGSettingsControllerState: Equatable {
    var searchQuery: String?
}

private typealias SGControllerEntry = SGItemListUIEntry<SGControllerSection, SGBoolSetting, SGSliderSetting, SGOneFromManySetting, SGDisclosureLink, AnyHashable>

private func SGControllerEntries(presentationData: PresentationData, callListSettings: CallListSettings, experimentalUISettings: ExperimentalUISettings, appConfiguration: AppConfiguration, nameColors: PeerNameColors, state: SGSettingsControllerState, page: UgramSettingsPage) -> [SGControllerEntry] {
    
    let lang = presentationData.strings.baseLanguageCode
    let strings = presentationData.strings
    let newStr = strings.Settings_New
    var entries: [SGControllerEntry] = []
    
    let id = SGItemListCounter()
    
    entries.append(.searchInput(id: id.count, section: .search, title: NSAttributedString(string: "🔍"), text: state.searchQuery ?? "", placeholder: strings.Common_Search))

    // MARK: Ugram
    let isRussian = lang == "ru"
    let t: (String, String) -> String = { ru, en in
        return isRussian ? ru : en
    }
    let ugram = UgramSettings.shared
    if page == .basic {
        entries.append(.oneFromManySelector(id: id.count, section: .ugramBasic, settingName: .ugramRecommended, text: t("Включить рекомендуемое ✨", "Turn on recommended ✨"), value: "", enabled: true))
        entries.append(.notice(id: id.count, section: .ugramBasic, text: t("Одним нажатием: удалённые сообщения, исчезающие медиа, история правок, скрытый просмотр историй и безлимитные закрепы.", "One tap: deleted messages, self-destructing media, edit history, story stealth mode and unlimited pins.")))
        entries.append(.toggle(id: id.count, section: .ugramBasic, settingName: .ugramSaveDeletedMessages, value: ugram.bool("ugramSaveDeletedMessages", default: true), text: t("Удалённые сообщения", "Deleted messages"), enabled: true))
        entries.append(.toggle(id: id.count, section: .ugramBasic, settingName: .ugramKeepSelfDestructingMedia, value: ugram.bool("ugramKeepSelfDestructingMedia", default: true), text: t("Сохранять исчезающие медиа", "Keep self-destructing media"), enabled: true))
        entries.append(.toggle(id: id.count, section: .ugramBasic, settingName: .ugramEditHistory, value: ugram.bool("ugramEditHistory", default: true), text: t("История правок", "Edit history"), enabled: true))
        entries.append(.toggle(id: id.count, section: .ugramBasic, settingName: .ugramNoReadReceipts, value: ugram.bool("ugramNoReadReceipts", default: false), text: t("Не отправлять «прочитано»", "Don't send read receipts"), enabled: true))
        entries.append(.toggle(id: id.count, section: .ugramBasic, settingName: .ugramNoTyping, value: ugram.bool("ugramNoTyping", default: false), text: t("Не показывать «печатает…»", "Don't send typing status"), enabled: true))
        entries.append(.toggle(id: id.count, section: .ugramBasic, settingName: .ugramHideOnline, value: ugram.bool("ugramHideOnline", default: false), text: t("Не показывать «в сети»", "Don't send online status"), enabled: true))
        entries.append(.toggle(id: id.count, section: .ugramBasic, settingName: .storyStealthMode, value: SGSimpleSettings.shared.storyStealthMode, text: t("Скрытый просмотр историй", "Story stealth mode"), enabled: true))
        entries.append(.toggle(id: id.count, section: .ugramBasic, settingName: .ugramUnlimitedPins, value: ugram.bool("ugramUnlimitedPins", default: false), text: t("Безлимитные закрепы", "Unlimited pins"), enabled: true))
        entries.append(.toggle(id: id.count, section: .ugramBasic, settingName: .ugramDisableAutoDownload, value: ugram.bool("ugramDisableAutoDownload", default: false), text: t("Отключить автозагрузку медиа", "Disable media auto-download"), enabled: true))
        entries.append(.notice(id: id.count, section: .ugramBasic, text: t("Здесь собраны самые нужные функции. Всё остальное и подробные описания — в других разделах Ugram Tools.", "The most useful features in one place. Everything else, with details, is in the other Ugram Tools sections.")))
    }

    entries.append(.header(id: id.count, section: .ugramDeleted, text: t("УДАЛЁННЫЕ СООБЩЕНИЯ", "DELETED MESSAGES"), badge: nil))
    entries.append(.toggle(id: id.count, section: .ugramDeleted, settingName: .ugramSaveDeletedMessages, value: ugram.bool("ugramSaveDeletedMessages", default: true), text: t("Удалённые сообщения", "Deleted messages"), enabled: true))
    entries.append(.toggle(id: id.count, section: .ugramDeleted, settingName: .ugramMarkDeletedMessages, value: ugram.bool("ugramMarkDeletedMessages", default: true), text: t("Метка 🗑 у удалённых", "Mark deleted with 🗑"), enabled: ugram.bool("ugramSaveDeletedMessages", default: true)))
    entries.append(.notice(id: id.count, section: .ugramDeleted, text: t("Сообщения, которые собеседник удалил у всех, остаются в чате на этом устройстве с меткой 🗑. Сохраняется только то, что уже было загружено в приложение. Секретные чаты не сохраняются.", "Messages deleted for everyone stay in the chat on this device with a 🗑 mark. Only messages already loaded by the app are kept. Secret chats are not kept.")))
    entries.append(.toggle(id: id.count, section: .ugramDeleted, settingName: .ugramEditHistory, value: ugram.bool("ugramEditHistory", default: true), text: t("История правок", "Edit history"), enabled: true))
    entries.append(.notice(id: id.count, section: .ugramDeleted, text: t("Зажмите отредактированное сообщение и выберите «История правок», чтобы увидеть прошлые версии. Запоминаются правки, сделанные после установки Ugram, пока приложение получало обновления.", "Long-press an edited message and choose \"Edit history\" to see earlier versions. Edits made after installing Ugram, while the app was receiving updates, are remembered.")))
    entries.append(.toggle(id: id.count, section: .ugramDeleted, settingName: .ugramKeepSelfDestructingMedia, value: ugram.bool("ugramKeepSelfDestructingMedia", default: true), text: t("Сохранять исчезающие медиа", "Keep self-destructing media"), enabled: true))
    entries.append(.notice(id: id.count, section: .ugramDeleted, text: t("Одноразовые фото, видео и голосовые приходят как обычные: их можно открывать сколько угодно раз и сохранять. Действует на медиа, полученные после включения.", "View-once photos, videos and voice messages arrive as regular media: open and save them any number of times. Applies to media received after turning this on.")))

    entries.append(.header(id: id.count, section: .ugramAdmin, text: t("ВАШИ ГРУППЫ И КАНАЛЫ", "YOUR GROUPS AND CHANNELS"), badge: nil))
    entries.append(.toggle(id: id.count, section: .ugramAdmin, settingName: .ugramAutoApproveJoinRequests, value: ugram.bool("ugramAutoApproveJoinRequests", default: false), text: t("Авто-принятие заявок", "Auto-approve join requests"), enabled: true))
    entries.append(.notice(id: id.count, section: .ugramAdmin, text: t("Заявки на вступление в группы и каналы, где вы администратор, одобряются сразу, как только приходят. Работает, пока Ugram запущен.", "Join requests to groups and channels you administer are approved as soon as they arrive. Works while Ugram is running.")))

    entries.append(.oneFromManySelector(id: id.count, section: .ugramAdmin, settingName: .ugramAdminFolders, text: t("Папки админа", "Admin folders"), value: t("Обновить", "Update"), enabled: true))
    entries.append(.notice(id: id.count, section: .ugramAdmin, text: t("Создаёт папки «Мои группы» и «Мои каналы» с чатами, где вы владелец или администратор. Нажмите ещё раз, чтобы обновить их после изменений.", "Creates \"My groups\" and \"My channels\" folders with the chats you own or administer. Tap again to refresh them after changes.")))

    entries.append(.header(id: id.count, section: .ugramChatList, text: t("СПИСОК ЧАТОВ", "CHAT LIST"), badge: nil))
    entries.append(.toggle(id: id.count, section: .ugramChatList, settingName: .ugramUnlimitedPins, value: ugram.bool("ugramUnlimitedPins", default: false), text: t("Безлимитные закрепы", "Unlimited pins"), enabled: true))
    entries.append(.notice(id: id.count, section: .ugramChatList, text: t("Закрепляйте сколько угодно чатов. Закрепы сверх лимита Telegram хранятся только на этом устройстве.", "Pin as many chats as you like. Pins over the Telegram limit are kept on this device only.")))
    entries.append(.oneFromManySelector(id: id.count, section: .ugramChatList, settingName: .ugramUnreadReminder, text: t("Напоминать о непрочитанном", "Unread reminder"), value: ugramReminderTitle(ugram.int("ugramUnreadReminderHours", default: 0), isRussian: isRussian), enabled: true))
    entries.append(.notice(id: id.count, section: .ugramChatList, text: t("Если вы закрыли Ugram, а непрочитанные сообщения остались, через выбранное время придёт напоминание.", "If you leave Ugram with unread messages, a reminder arrives after the chosen time.")))
    entries.append(.toggle(id: id.count, section: .ugramChatList, settingName: .ugramInstantPush, value: ugram.bool("ugramInstantPush", default: false), text: t("Мгновенные уведомления ⚡️", "Instant notifications ⚡️"), enabled: true))
    entries.append(.oneFromManySelector(id: id.count, section: .ugramChatList, settingName: .ugramNtfySubscribe, text: t("Подписаться в ntfy", "Subscribe in ntfy"), value: ugram.bool("ugramInstantPush", default: false) ? t("Открыть", "Open") : t("Сначала включите", "Turn on first"), enabled: ugram.bool("ugramInstantPush", default: false)))
    entries.append(.notice(id: id.count, section: .ugramChatList, text: t("Настоящие пуши без сервера: Telegram сообщает о новом сообщении на вашу личную тему ntfy.sh, а бесплатное приложение ntfy показывает уведомление. 1) Установите ntfy из App Store. 2) Включите переключатель. 3) Нажмите «Подписаться в ntfy» — тема откроется в приложении (или скопируется, если ntfy ещё не установлен: вставьте её в ntfy через «+»). В уведомлении нет текста сообщения — только «Новое сообщение»; нажатие открывает Ugram. Пуши приходят, когда Ugram закрыт или свёрнут.", "Real pushes without a server: Telegram reports new messages to your private ntfy.sh topic and the free ntfy app shows a notification. 1) Install ntfy from the App Store. 2) Turn this on. 3) Tap \"Subscribe in ntfy\" — the topic opens in the app (or is copied if ntfy isn't installed yet: add it in ntfy with \"+\"). The notification has no message text, just \"New message\"; tapping it opens Ugram. Pushes arrive while Ugram is closed or in the background.")))
    entries.append(.toggle(id: id.count, section: .ugramChatList, settingName: .ugramBackgroundNotifications, value: ugram.bool("ugramBackgroundNotifications", default: false), text: t("Фоновые уведомления 🔔", "Background notifications 🔔"), enabled: true))
    entries.append(.notice(id: id.count, section: .ugramChatList, text: t("Обычные пуши в переподписанном Ugram не работают. Вместо них iOS иногда будит приложение в фоне (обычно раз в 15 минут – несколько часов, как решит система), Ugram синхронизируется и присылает уведомление о новых сообщениях. Не закрывайте Ugram смахиванием и не отключайте «Обновление контента» в настройках iPhone.", "Regular push doesn't work in a re-signed Ugram. Instead iOS wakes the app in the background now and then (usually every 15 minutes to a few hours, as the system decides); Ugram syncs and notifies you about new messages. Don't swipe Ugram away and keep Background App Refresh on.")))

    entries.append(.header(id: id.count, section: .ugramGhost, text: t("РЕЖИМ ПРИЗРАКА", "GHOST MODE"), badge: nil))
    entries.append(.toggle(id: id.count, section: .ugramGhost, settingName: .ugramNoReadReceipts, value: ugram.bool("ugramNoReadReceipts", default: false), text: t("Не отправлять «прочитано»", "Don't send read receipts"), enabled: true))
    entries.append(.toggle(id: id.count, section: .ugramGhost, settingName: .ugramNoTyping, value: ugram.bool("ugramNoTyping", default: false), text: t("Не показывать «печатает…»", "Don't send typing status"), enabled: true))
    entries.append(.toggle(id: id.count, section: .ugramGhost, settingName: .ugramHideOnline, value: ugram.bool("ugramHideOnline", default: false), text: t("Не показывать «в сети»", "Don't send online status"), enabled: true))
    entries.append(.toggle(id: id.count, section: .ugramGhost, settingName: .storyStealthMode, value: SGSimpleSettings.shared.storyStealthMode, text: t("Скрытый просмотр историй", "Story stealth mode"), enabled: true))
    entries.append(.notice(id: id.count, section: .ugramGhost, text: t("Пока «прочитано» выключено, чаты могут снова становиться непрочитанными после синхронизации. Отправка сообщения всё равно показывает вас в сети.", "While read receipts are off, chats may become unread again after a sync. Sending a message still makes you appear online.")))

    entries.append(.header(id: id.count, section: .ugramMessages, text: t("ИСХОДЯЩИЕ СООБЩЕНИЯ", "OUTGOING MESSAGES"), badge: nil))
    entries.append(.oneFromManySelector(id: id.count, section: .ugramMessages, settingName: .ugramTextStyle, text: t("Стиль текста", "Text style"), value: ugramTextStyleTitle(ugram.string("ugramTextStyle") ?? "", isRussian: isRussian), enabled: true))
    entries.append(.oneFromManySelector(id: id.count, section: .ugramMessages, settingName: .ugramAutoPostfix, text: t("Авто-постфикс", "Auto-postfix"), value: ugram.string("ugramAutoPostfix") ?? t("Отключено", "Off"), enabled: true))
    entries.append(.toggle(id: id.count, section: .ugramMessages, settingName: .ugramHeartEffect, value: ugram.bool("ugramHeartEffect", default: false), text: t("Эффект сердечка ❤️", "Heart effect ❤️"), enabled: true))
    entries.append(.toggle(id: id.count, section: .ugramMessages, settingName: .ugramAutoSticker, value: ugram.bool("ugramAutoSticker", default: false), text: t("Авто-стикер", "Auto-sticker"), enabled: true))
    entries.append(.notice(id: id.count, section: .ugramMessages, text: t("Стиль применяется ко всему тексту сообщения. Постфикс добавляется новой строкой в конец. Сердечко — анимированный эффект ❤️, работает только в личных чатах. Авто-стикер отправляет после текстового сообщения последний использованный стикер. Команды ботам (/…) не меняются.", "The style applies to the whole message text. The postfix is added on a new line at the end. The heart is an animated ❤️ effect, private chats only. Auto-sticker sends your most recent sticker after a text message. Bot commands (/…) are left as is.")))

    entries.append(.header(id: id.count, section: .ugramMedia, text: t("АВТОЗАГРУЗКА", "AUTO-DOWNLOAD"), badge: nil))
    entries.append(.toggle(id: id.count, section: .ugramMedia, settingName: .ugramDisableAutoDownload, value: ugram.bool("ugramDisableAutoDownload", default: false), text: t("Отключить автозагрузку", "Disable auto-download"), enabled: true))
    entries.append(.notice(id: id.count, section: .ugramMedia, text: t("Фото, видео и файлы не скачиваются сами ни по мобильной сети, ни по Wi-Fi: нажмите на медиа, чтобы загрузить. Стикеры загружаются как обычно.", "Photos, videos and files are not downloaded by themselves on cellular or Wi-Fi: tap media to load it. Stickers load as usual.")))
    
    
    if SGSimpleSettings.shared.canUseNY {
        entries.append(.header(id: id.count, section: .trending, text: i18n("Settings.NY.Header", lang), badge: newStr))
        entries.append(.toggle(id: id.count, section: .trending, settingName: .nyStyleSnow, value: SGSimpleSettings.shared.nyStyle == SGSimpleSettings.NYStyle.snow.rawValue, text: i18n("Settings.NY.Style.snow", lang), enabled: true))
        entries.append(.toggle(id: id.count, section: .trending, settingName: .nyStyleLightning, value: SGSimpleSettings.shared.nyStyle == SGSimpleSettings.NYStyle.lightning.rawValue, text: i18n("Settings.NY.Style.lightning", lang), enabled: true))
        // entries.append(.oneFromManySelector(id: id.count, section: .trending, settingName: .nyStyle, text: i18n("Settings.NY.Style", lang), value: i18n("Settings.NY.Style.\(SGSimpleSettings.shared.nyStyle)", lang), enabled: true))
        entries.append(.notice(id: id.count, section: .trending, text: i18n("Settings.NY.Notice", lang)))
    } else {
        id.increment(3)
    }
    
    if appConfiguration.sgWebSettings.global.canEditSettings {
        entries.append(.disclosure(id: id.count, section: .content, link: .contentSettings, text: i18n("Settings.ContentSettings", lang)))
    } else {
        id.increment(1)
    }
    
    entries.append(.header(id: id.count, section: .tabs, text: t("DYNAMIC ISLAND", "DYNAMIC ISLAND"), badge: nil)) // MARK: Ugram
    entries.append(.oneFromManySelector(id: id.count, section: .tabs, settingName: .ugramIslandBadge, text: t("Значок Ugram у острова", "Ugram badge by the island"), value: ugramIslandBadgeTitle(SGSimpleSettings.shared.customAppBadge, isRussian: isRussian), enabled: true))
    entries.append(.notice(id: id.count, section: .tabs, text: t("Плашка «⚡ UGRAM» рядом с Dynamic Island. Выберите цвет или скройте её.", "The \"⚡ UGRAM\" badge beside the Dynamic Island. Pick a colour or hide it.")))
    entries.append(.header(id: id.count, section: .tabs, text: i18n("Settings.Tabs.Header", lang), badge: nil))
    entries.append(.toggle(id: id.count, section: .tabs, settingName: .hideTabBar, value: SGSimpleSettings.shared.hideTabBar, text: i18n("Settings.Tabs.HideTabBar", lang), enabled: true))
    entries.append(.toggle(id: id.count, section: .tabs, settingName: .showContactsTab, value: callListSettings.showContactsTab, text: i18n("Settings.Tabs.ShowContacts", lang), enabled: !SGSimpleSettings.shared.hideTabBar))
    entries.append(.toggle(id: id.count, section: .tabs, settingName: .showCallsTab, value: callListSettings.showTab, text: strings.CallSettings_TabIcon, enabled: !SGSimpleSettings.shared.hideTabBar))
    entries.append(.toggle(id: id.count, section: .tabs, settingName: .showTabNames, value: SGSimpleSettings.shared.showTabNames, text: i18n("Settings.Tabs.ShowNames", lang), enabled: !SGSimpleSettings.shared.hideTabBar))
    entries.append(.toggle(id: id.count, section: .tabs, settingName: .tabBarSearchEnabled, value: SGSimpleSettings.shared.tabBarSearchEnabled, text: i18n("Settings.Tabs.SearchButton", lang), enabled: !SGSimpleSettings.shared.hideTabBar))
    entries.append(.toggle(id: id.count, section: .tabs, settingName: .wideTabBar, value: SGSimpleSettings.shared.wideTabBar, text: i18n("Settings.Tabs.WideTabBar", lang), enabled: !SGSimpleSettings.shared.hideTabBar))
    entries.append(.notice(id: id.count, section: .tabs, text: i18n("Settings.Tabs.WideTabBar.Notice", lang)))
    
    entries.append(.header(id: id.count, section: .folders, text: strings.Settings_ChatFolders.uppercased(), badge: nil))
    entries.append(.toggle(id: id.count, section: .folders, settingName: .foldersAtBottom, value: experimentalUISettings.foldersTabAtBottom, text: i18n("Settings.Folders.BottomTab", lang), enabled: true))
    entries.append(.toggle(id: id.count, section: .folders, settingName: .allChatsHidden, value: SGSimpleSettings.shared.allChatsHidden, text: i18n("Settings.Folders.AllChatsHidden", lang, strings.ChatList_Tabs_AllChats), enabled: true))
    #if DEBUG
//    entries.append(.oneFromManySelector(id: id.count, section: .folders, settingName: .allChatsFolderPositionOverride, text: i18n("Settings.Folders.AllChatsPlacement", lang), value: i18n("Settings.Folders.AllChatsPlacement.\(SGSimpleSettings.shared.allChatsFolderPositionOverride)", lang), enabled: true))
    #endif
    entries.append(.toggle(id: id.count, section: .folders, settingName: .compactFolderNames, value: SGSimpleSettings.shared.compactFolderNames, text: i18n("Settings.Folders.CompactNames", lang), enabled: true))
    entries.append(.oneFromManySelector(id: id.count, section: .folders, settingName: .allChatsTitleLengthOverride, text: i18n("Settings.Folders.AllChatsTitle", lang), value: i18n("Settings.Folders.AllChatsTitle.\(SGSimpleSettings.shared.allChatsTitleLengthOverride)", lang), enabled: true))
    entries.append(.toggle(id: id.count, section: .folders, settingName: .rememberLastFolder, value: SGSimpleSettings.shared.rememberLastFolder, text: i18n("Settings.Folders.RememberLast", lang), enabled: true))
    entries.append(.notice(id: id.count, section: .folders, text: i18n("Settings.Folders.RememberLast.Notice", lang)))
    
    entries.append(.header(id: id.count, section: .chatList, text: i18n("Settings.ChatList.Header", lang), badge: nil))
    entries.append(.toggle(id: id.count, section: .chatList, settingName: .compactChatList, value: SGSimpleSettings.shared.compactChatList, text: i18n("Settings.CompactChatList", lang), enabled: true))
    entries.append(.toggle(id: id.count, section: .chatList, settingName: .compactMessagePreview, value: SGSimpleSettings.shared.chatListLines != SGSimpleSettings.ChatListLines.three.rawValue, text: i18n("Settings.CompactMessagePreview", lang), enabled: true))
    entries.append(.toggle(id: id.count, section: .chatList, settingName: .disableChatSwipeOptions, value: !SGSimpleSettings.shared.disableChatSwipeOptions, text: i18n("Settings.ChatSwipeOptions", lang), enabled: true))
    entries.append(.toggle(id: id.count, section: .chatList, settingName: .disableDeleteChatSwipeOption, value: !SGSimpleSettings.shared.disableDeleteChatSwipeOption, text: i18n("Settings.DeleteChatSwipeOption", lang), enabled: !SGSimpleSettings.shared.disableChatSwipeOptions))
    
    entries.append(.header(id: id.count, section: .profiles, text: i18n("Settings.Profiles.Header", lang), badge: nil))
    entries.append(.toggle(id: id.count, section: .profiles, settingName: .showProfileId, value: SGSimpleSettings.shared.showProfileId, text: i18n("Settings.ShowProfileID", lang), enabled: true))
    entries.append(.toggle(id: id.count, section: .profiles, settingName: .showDC, value: SGSimpleSettings.shared.showDC, text: i18n("Settings.ShowDC", lang), enabled: true))
    entries.append(.toggle(id: id.count, section: .profiles, settingName: .showRegDate, value: SGSimpleSettings.shared.showRegDate, text: i18n("Settings.ShowRegDate", lang), enabled: true))
    entries.append(.notice(id: id.count, section: .profiles, text: i18n("Settings.ShowRegDate.Notice", lang)))
    entries.append(.toggle(id: id.count, section: .profiles, settingName: .showCreationDate, value: SGSimpleSettings.shared.showCreationDate, text: i18n("Settings.ShowCreationDate", lang), enabled: true))
    entries.append(.notice(id: id.count, section: .profiles, text: i18n("Settings.ShowCreationDate.Notice", lang)))
    entries.append(.toggle(id: id.count, section: .profiles, settingName: .confirmCalls, value: SGSimpleSettings.shared.confirmCalls, text: i18n("Settings.CallConfirmation", lang), enabled: true))
    entries.append(.notice(id: id.count, section: .profiles, text: i18n("Settings.CallConfirmation.Notice", lang)))
    
    entries.append(.header(id: id.count, section: .stories, text: strings.AutoDownloadSettings_Stories.uppercased(), badge: nil))
    entries.append(.toggle(id: id.count, section: .stories, settingName: .hideStories, value: SGSimpleSettings.shared.hideStories, text: i18n("Settings.Stories.Hide", lang), enabled: true))
    entries.append(.toggle(id: id.count, section: .stories, settingName: .disableSwipeToRecordStory, value: SGSimpleSettings.shared.disableSwipeToRecordStory, text: i18n("Settings.Stories.DisableSwipeToRecord", lang), enabled: true))
    entries.append(.toggle(id: id.count, section: .stories, settingName: .warnOnStoriesOpen, value: SGSimpleSettings.shared.warnOnStoriesOpen, text: i18n("Settings.Stories.WarnBeforeView", lang), enabled: true))
    entries.append(.toggle(id: id.count, section: .stories, settingName: .showRepostToStory, value: SGSimpleSettings.shared.showRepostToStoryV2, text: strings.Share_RepostToStory.replacingOccurrences(of: "\n", with: " "), enabled: true))
    if SGSimpleSettings.shared.canUseStealthMode {
        entries.append(.toggle(id: id.count, section: .stories, settingName: .storyStealthMode, value: SGSimpleSettings.shared.storyStealthMode, text: strings.Story_StealthMode_Title, enabled: true))
        entries.append(.notice(id: id.count, section: .stories, text: strings.Story_StealthMode_ControlText))
    } else {
        id.increment(2)
    }

    
    entries.append(.header(id: id.count, section: .translation, text: strings.Localization_TranslateMessages.uppercased(), badge: nil))
    entries.append(.oneFromManySelector(id: id.count, section: .translation, settingName: .translationBackend, text: i18n("Settings.Translation.Backend", lang), value: i18n("Settings.Translation.Backend.\(SGSimpleSettings.shared.translationBackend)", lang), enabled: true))
    if SGSimpleSettings.shared.translationBackendEnum != .gtranslate {
        entries.append(.notice(id: id.count, section: .translation, text: i18n("Settings.Translation.Backend.Notice", lang, "Settings.Translation.Backend.\(SGSimpleSettings.TranslationBackend.gtranslate.rawValue)".i18n(lang))))
    } else {
        id.increment(1)
    }
    entries.append(.toggle(id: id.count, section: .translation, settingName: .quickTranslateButton, value: SGSimpleSettings.shared.quickTranslateButton, text: i18n("Settings.Translation.QuickTranslateButton", lang), enabled: true))
    entries.append(.disclosure(id: id.count, section: .translation, link: .languageSettings, text: strings.Localization_TranslateEntireChat))
    entries.append(.notice(id: id.count, section: .translation, text: i18n("Common.NoTelegramPremiumNeeded", lang, strings.Settings_Premium)))

    entries.append(.header(id: id.count, section: .voiceMessages, text: "Settings.Transcription.Header".i18n(lang), badge: nil))
    entries.append(.oneFromManySelector(id: id.count, section: .voiceMessages, settingName: .transcriptionBackend, text: i18n("Settings.Transcription.Backend", lang), value: i18n("Settings.Transcription.Backend.\(SGSimpleSettings.shared.transcriptionBackend)", lang), enabled: true))
    if SGSimpleSettings.shared.transcriptionBackendEnum != .apple {
        entries.append(.notice(id: id.count, section: .voiceMessages, text: i18n("Settings.Transcription.Backend.Notice", lang, "Settings.Transcription.Backend.\(SGSimpleSettings.TranscriptionBackend.apple.rawValue)".i18n(lang))))
    } else {
        id.increment(1)
    }
    entries.append(.header(id: id.count, section: .voiceMessages, text: strings.Privacy_VoiceMessages.uppercased(), badge: nil))
    entries.append(.toggle(id: id.count, section: .voiceMessages, settingName: .forceBuiltInMic, value: SGSimpleSettings.shared.forceBuiltInMic, text: i18n("Settings.forceBuiltInMic", lang), enabled: true))
    entries.append(.notice(id: id.count, section: .voiceMessages, text: i18n("Settings.forceBuiltInMic.Notice", lang)))

    entries.append(.header(id: id.count, section: .calls, text: strings.Calls_TabTitle.uppercased(), badge: nil))
    entries.append(.toggle(id: id.count, section: .calls, settingName: .enableVoipTcp, value: experimentalUISettings.enableVoipTcp, text: "Force TCP", enabled: true))
    entries.append(.notice(id: id.count, section: .calls, text: "Common.KnowWhatYouDo".i18n(lang)))
    
    entries.append(.header(id: id.count, section: .photo, text: strings.NetworkUsageSettings_MediaImageDataSection, badge: nil))
    entries.append(.header(id: id.count, section: .photo, text: strings.PhotoEditor_QualityTool.uppercased(), badge: nil))
    entries.append(.percentageSlider(id: id.count, section: .photo, settingName: .outgoingPhotoQuality, value: SGSimpleSettings.shared.outgoingPhotoQuality))
    entries.append(.notice(id: id.count, section: .photo, text: i18n("Settings.Photo.Quality.Notice", lang)))
    entries.append(.toggle(id: id.count, section: .photo, settingName: .sendLargePhotos, value: SGSimpleSettings.shared.sendLargePhotos, text: i18n("Settings.Photo.SendLarge", lang), enabled: true))
    entries.append(.notice(id: id.count, section: .photo, text: i18n("Settings.Photo.SendLarge.Notice", lang)))
    
    entries.append(.header(id: id.count, section: .stickers, text: strings.StickerPacksSettings_Title.uppercased(), badge: nil))
    entries.append(.header(id: id.count, section: .stickers, text: i18n("Settings.Stickers.Size", lang), badge: nil))
    entries.append(.percentageSlider(id: id.count, section: .stickers, settingName: .stickerSize, value: SGSimpleSettings.shared.stickerSize))
    entries.append(.toggle(id: id.count, section: .stickers, settingName: .stickerTimestamp, value: SGSimpleSettings.shared.stickerTimestamp, text: i18n("Settings.Stickers.Timestamp", lang), enabled: true))
    
    
    entries.append(.header(id: id.count, section: .videoNotes, text: i18n("Settings.VideoNotes.Header", lang), badge: nil))
    entries.append(.toggle(id: id.count, section: .videoNotes, settingName: .startTelescopeWithRearCam, value: SGSimpleSettings.shared.startTelescopeWithRearCam, text: i18n("Settings.VideoNotes.StartWithRearCam", lang), enabled: true))
    
    entries.append(.header(id: id.count, section: .contextMenu, text: i18n("Settings.ContextMenu", lang), badge: nil))
    entries.append(.notice(id: id.count, section: .contextMenu, text: i18n("Settings.ContextMenu.Notice", lang)))
    entries.append(.toggle(id: id.count, section: .contextMenu, settingName: .contextShowSaveToCloud, value: SGSimpleSettings.shared.contextShowSaveToCloud, text: i18n("ContextMenu.SaveToCloud", lang), enabled: true))
    entries.append(.toggle(id: id.count, section: .contextMenu, settingName: .contextShowHideForwardName, value: SGSimpleSettings.shared.contextShowHideForwardName, text: strings.Conversation_ForwardOptions_HideSendersNames, enabled: true))
    entries.append(.toggle(id: id.count, section: .contextMenu, settingName: .contextShowSelectFromUser, value: SGSimpleSettings.shared.contextShowSelectFromUser, text: i18n("ContextMenu.SelectFromUser", lang), enabled: true))
    entries.append(.toggle(id: id.count, section: .contextMenu, settingName: .contextShowRestrict, value: SGSimpleSettings.shared.contextShowRestrict, text: strings.Conversation_ContextMenuBan, enabled: true))
    entries.append(.toggle(id: id.count, section: .contextMenu, settingName: .contextShowReport, value: SGSimpleSettings.shared.contextShowReport, text: strings.Conversation_ContextMenuReport, enabled: true))
    entries.append(.toggle(id: id.count, section: .contextMenu, settingName: .contextShowReply, value: SGSimpleSettings.shared.contextShowReply, text: strings.Conversation_ContextMenuReply, enabled: true))
    entries.append(.toggle(id: id.count, section: .contextMenu, settingName: .contextShowPin, value: SGSimpleSettings.shared.contextShowPin, text: strings.Conversation_Pin, enabled: true))
    entries.append(.toggle(id: id.count, section: .contextMenu, settingName: .contextShowSaveMedia, value: SGSimpleSettings.shared.contextShowSaveMedia, text: strings.Conversation_SaveToFiles, enabled: true))
    entries.append(.toggle(id: id.count, section: .contextMenu, settingName: .contextShowMessageReplies, value: SGSimpleSettings.shared.contextShowMessageReplies, text: strings.Conversation_ContextViewThread, enabled: true))
    entries.append(.toggle(id: id.count, section: .contextMenu, settingName: .contextShowJson, value: SGSimpleSettings.shared.contextShowJson, text: "JSON", enabled: true))
    /* entries.append(.toggle(id: id.count, section: .contextMenu, settingName: .contextShowRestrict, value: SGSimpleSettings.shared.contextShowRestrict, text: strings.Conversation_ContextMenuBan)) */
    
    entries.append(.header(id: id.count, section: .accountColors, text: i18n("Settings.CustomColors.Header", lang), badge: nil))
    entries.append(.header(id: id.count, section: .accountColors, text: i18n("Settings.CustomColors.Saturation", lang), badge: nil))
    let accountColorSaturation = SGSimpleSettings.shared.accountColorsSaturation
    entries.append(.percentageSlider(id: id.count, section: .accountColors, settingName: .accountColorsSaturation, value: accountColorSaturation))
//    let nameColor: PeerNameColor
//    if let updatedNameColor = state.updatedNameColor {
//        nameColor = updatedNameColor
//    } else {
//        nameColor = .blue
//    }
//    let _ = nameColors.get(nameColor, dark: presentationData.theme.overallDarkAppearance)
//    entries.append(.peerColorPicker(id: entries.count, section: .other,
//        colors: nameColors,
//        currentColor: nameColor, // TODO: PeerNameColor(rawValue: <#T##Int32#>)
//        currentSaturation: accountColorSaturation
//    ))
    
    if accountColorSaturation == 0 {
        id.increment(100)
        entries.append(.peerColorDisclosurePreview(id: id.count, section: .accountColors, name: "\(strings.UserInfo_FirstNamePlaceholder) \(strings.UserInfo_LastNamePlaceholder)", color:         presentationData.theme.chat.message.incoming.accentTextColor))
    } else {
        id.increment(200)
        for index in nameColors.displayOrder.prefix(3) {
            let color: PeerNameColor = PeerNameColor(rawValue: index)
            let colors = nameColors.get(color, dark: presentationData.theme.overallDarkAppearance)
            entries.append(.peerColorDisclosurePreview(id: id.count, section: .accountColors, name: "\(strings.UserInfo_FirstNamePlaceholder) \(strings.UserInfo_LastNamePlaceholder)", color: colors.main))
        }
    }
    entries.append(.notice(id: id.count, section: .accountColors, text: i18n("Settings.CustomColors.Saturation.Notice", lang)))
    
    id.increment(10000)
    entries.append(.header(id: id.count, section: .other, text: strings.Appearance_Other.uppercased(), badge: nil))
    entries.append(.toggle(id: id.count, section: .other, settingName: .combinedMediaViewer, value: SGSimpleSettings.shared.combinedMediaViewer, text: i18n("Settings.CombinedMediaViewer", lang), enabled: true))
    entries.append(.notice(id: id.count, section: .other, text: i18n("Settings.CombinedMediaViewer.Notice", lang)))
    entries.append(.toggle(id: id.count, section: .other, settingName: .videoControlsInFooter, value: SGSimpleSettings.shared.videoControlsInFooter, text: i18n("Settings.videoControlsInFooter", lang), enabled: true))
    entries.append(.toggle(id: id.count, section: .other, settingName: .swipeForVideoPIP, value: SGSimpleSettings.shared.videoPIPSwipeDirection == SGSimpleSettings.VideoPIPSwipeDirection.up.rawValue, text: i18n("Settings.swipeForVideoPIP", lang), enabled: true))
    entries.append(.notice(id: id.count, section: .other, text: i18n("Settings.swipeForVideoPIP.Notice", lang)))
    entries.append(.toggle(id: id.count, section: .other, settingName: .hideChannelBottomButton, value: !SGSimpleSettings.shared.hideChannelBottomButton, text: i18n("Settings.showChannelBottomButton", lang), enabled: true))
    entries.append(.toggle(id: id.count, section: .other, settingName: .wideChannelPosts, value: SGSimpleSettings.shared.wideChannelPosts, text: i18n("Settings.wideChannelPosts", lang), enabled: true))
    entries.append(.toggle(id: id.count, section: .other, settingName: .secondsInMessages, value: SGSimpleSettings.shared.secondsInMessages, text: i18n("Settings.secondsInMessages", lang), enabled: true))
    entries.append(.toggle(id: id.count, section: .other, settingName: .messageDoubleTapActionOutgoingEdit, value: SGSimpleSettings.shared.messageDoubleTapActionOutgoing == SGSimpleSettings.MessageDoubleTapAction.edit.rawValue, text: i18n("Settings.messageDoubleTapActionOutgoingEdit", lang), enabled: true))
    entries.append(.toggle(id: id.count, section: .other, settingName: .hideRecordingButton, value: !SGSimpleSettings.shared.hideRecordingButton, text: i18n("Settings.RecordingButton", lang), enabled: true))
    entries.append(.toggle(id: id.count, section: .other, settingName: .disableSnapDeletionEffect, value: !SGSimpleSettings.shared.disableSnapDeletionEffect, text: i18n("Settings.SnapDeletionEffect", lang), enabled: true))
    entries.append(.toggle(id: id.count, section: .other, settingName: .disableSendAsButton, value: !SGSimpleSettings.shared.disableSendAsButton, text: i18n("Settings.SendAsButton", lang, strings.Conversation_SendMesageAs), enabled: true))
    entries.append(.toggle(id: id.count, section: .other, settingName: .disableGalleryCamera, value: !SGSimpleSettings.shared.disableGalleryCamera, text: i18n("Settings.GalleryCamera", lang), enabled: true))
    entries.append(.toggle(id: id.count, section: .other, settingName: .disableGalleryCameraPreview, value: !SGSimpleSettings.shared.disableGalleryCameraPreview, text: i18n("Settings.GalleryCameraPreview", lang), enabled: !SGSimpleSettings.shared.disableGalleryCamera))
    entries.append(.toggle(id: id.count, section: .other, settingName: .disableScrollToNextChannel, value: !SGSimpleSettings.shared.disableScrollToNextChannel, text: i18n("Settings.PullToNextChannel", lang), enabled: true))
    entries.append(.toggle(id: id.count, section: .other, settingName: .disableScrollToNextTopic, value: !SGSimpleSettings.shared.disableScrollToNextTopic, text: i18n("Settings.PullToNextTopic", lang), enabled: true))
    entries.append(.toggle(id: id.count, section: .other, settingName: .hideReactions, value: SGSimpleSettings.shared.hideReactions, text: i18n("Settings.HideReactions", lang), enabled: true))
    entries.append(.toggle(id: id.count, section: .other, settingName: .uploadSpeedBoost, value: SGSimpleSettings.shared.uploadSpeedBoost, text: i18n("Settings.UploadsBoost", lang), enabled: true))
    entries.append(.oneFromManySelector(id: id.count, section: .other, settingName: .downloadSpeedBoost, text: i18n("Settings.DownloadsBoost", lang), value: i18n("Settings.DownloadsBoost.\(SGSimpleSettings.shared.downloadSpeedBoost)", lang), enabled: true))
    entries.append(.notice(id: id.count, section: .other, text: i18n("Settings.DownloadsBoost.Notice", lang)))
    entries.append(.toggle(id: id.count, section: .other, settingName: .sendWithReturnKey, value: SGSimpleSettings.shared.sendWithReturnKey, text: i18n("Settings.SendWithReturnKey", lang), enabled: true))
    entries.append(.toggle(id: id.count, section: .other, settingName: .forceEmojiTab, value: SGSimpleSettings.shared.forceEmojiTab, text: i18n("Settings.ForceEmojiTab", lang), enabled: true))
    entries.append(.toggle(id: id.count, section: .other, settingName: .defaultEmojisFirst, value: SGSimpleSettings.shared.defaultEmojisFirst, text: i18n("Settings.DefaultEmojisFirst", lang), enabled: true))
    entries.append(.notice(id: id.count, section: .other, text: i18n("Settings.DefaultEmojisFirst.Notice", lang)))
    entries.append(.toggle(id: id.count, section: .other, settingName: .hidePhoneInSettings, value: SGSimpleSettings.shared.hidePhoneInSettings, text: i18n("Settings.HidePhoneInSettingsUI", lang), enabled: true))
    entries.append(.notice(id: id.count, section: .other, text: i18n("Settings.HidePhoneInSettingsUI.Notice", lang)))
    entries.append(.toggle(id: id.count, section: .other, settingName: .hideAccountInNotifications, value: SGSimpleSettings.shared.hideAccountInNotifications, text: i18n("Settings.HideAccountInNotifications", lang), enabled: true))
    
    // MARK: Ugram
    if let sections = page.sections {
        let sectionIds = Set(sections.map { $0.rawValue })
        return entries.filter { sectionIds.contains($0.section) }
    }
    return filterSGItemListUIEntrires(entries: entries, by: state.searchQuery)
}

public func sgSettingsController(context: AccountContext, page: UgramSettingsPage = .all/*, focusOnItemTag: Int? = nil*/) -> ViewController {
    var presentControllerImpl: ((ViewController, ViewControllerPresentationArguments?) -> Void)?
    var pushControllerImpl: ((ViewController) -> Void)?
    var presentOneFromManyImpl: ((SGOneFromManySetting, [SGOneFromManyOption]) -> Void)?
//    var getRootControllerImpl: (() -> UIViewController?)?
//    var getNavigationControllerImpl: (() -> NavigationController?)?
    var askForRestart: (() -> Void)?
    
    let initialState = SGSettingsControllerState()
    let statePromise = ValuePromise(initialState, ignoreRepeated: true)
    let stateValue = Atomic(value: initialState)
    let updateState: ((SGSettingsControllerState) -> SGSettingsControllerState) -> Void = { f in
        statePromise.set(stateValue.modify { f($0) })
    }
    
//    let sliderPromise = ValuePromise(SGSimpleSettings.shared.accountColorsSaturation, ignoreRepeated: true)
//    let sliderStateValue = Atomic(value: SGSimpleSettings.shared.accountColorsSaturation)
//    let _: ((Int32) -> Int32) -> Void = { f in
//        sliderPromise.set(sliderStateValue.modify( {f($0)}))
//    }
    
    let simplePromise = ValuePromise(true, ignoreRepeated: false)
    
    let arguments = SGItemListArguments<SGBoolSetting, SGSliderSetting, SGOneFromManySetting, SGDisclosureLink, AnyHashable>(
        context: context,
        /*updatePeerColor: { color in
          updateState { state in
              var updatedState = state
              updatedState.updatedNameColor = color
              return updatedState
          }
        },*/ setBoolValue: { setting, value in
        switch setting {
        case .hidePhoneInSettings:
            SGSimpleSettings.shared.hidePhoneInSettings = value
            askForRestart?()
        case .showTabNames:
            SGSimpleSettings.shared.showTabNames = value
            askForRestart?()
        case .showContactsTab:
            let _ = (
                updateCallListSettingsInteractively(
                    accountManager: context.sharedContext.accountManager, { $0.withUpdatedShowContactsTab(value) }
                )
            ).start()
        case .showCallsTab:
            let _ = (
                updateCallListSettingsInteractively(
                    accountManager: context.sharedContext.accountManager, { $0.withUpdatedShowTab(value) }
                )
            ).start()
        case .tabBarSearchEnabled:
            SGSimpleSettings.shared.tabBarSearchEnabled = value
        case .wideTabBar:
            SGSimpleSettings.shared.wideTabBar = value
            askForRestart?()
        case .foldersAtBottom:
            let _ = (
                updateExperimentalUISettingsInteractively(accountManager: context.sharedContext.accountManager, { settings in
                        var settings = settings
                        settings.foldersTabAtBottom = value
                        return settings
                    }
                )
            ).start()
        case .startTelescopeWithRearCam:
            SGSimpleSettings.shared.startTelescopeWithRearCam = value
        case .hideStories:
            SGSimpleSettings.shared.hideStories = value
        case .showProfileId:
            SGSimpleSettings.shared.showProfileId = value
        case .warnOnStoriesOpen:
            SGSimpleSettings.shared.warnOnStoriesOpen = value
        case .sendWithReturnKey:
            SGSimpleSettings.shared.sendWithReturnKey = value
        case .rememberLastFolder:
            SGSimpleSettings.shared.rememberLastFolder = value
        case .sendLargePhotos:
            SGSimpleSettings.shared.sendLargePhotos = value
        case .storyStealthMode:
            SGSimpleSettings.shared.storyStealthMode = value
        case .disableSwipeToRecordStory:
            SGSimpleSettings.shared.disableSwipeToRecordStory = value
        case .quickTranslateButton:
            SGSimpleSettings.shared.quickTranslateButton = value
        case .uploadSpeedBoost:
            SGSimpleSettings.shared.uploadSpeedBoost = value
        case .hideReactions:
            SGSimpleSettings.shared.hideReactions = value
        case .showRepostToStory:
            SGSimpleSettings.shared.showRepostToStoryV2 = value
        case .contextShowSelectFromUser:
            SGSimpleSettings.shared.contextShowSelectFromUser = value
        case .contextShowSaveToCloud:
            SGSimpleSettings.shared.contextShowSaveToCloud = value
        case .contextShowRestrict:
            SGSimpleSettings.shared.contextShowRestrict = value
        case .contextShowHideForwardName:
            SGSimpleSettings.shared.contextShowHideForwardName = value
        case .disableScrollToNextChannel:
            SGSimpleSettings.shared.disableScrollToNextChannel = !value
        case .disableScrollToNextTopic:
            SGSimpleSettings.shared.disableScrollToNextTopic = !value
        case .disableChatSwipeOptions:
            SGSimpleSettings.shared.disableChatSwipeOptions = !value
            simplePromise.set(true) // Trigger update for 'enabled' field of other toggles
            askForRestart?()
        case .disableDeleteChatSwipeOption:
            SGSimpleSettings.shared.disableDeleteChatSwipeOption = !value
            askForRestart?()
        case .disableGalleryCamera:
            SGSimpleSettings.shared.disableGalleryCamera = !value
            simplePromise.set(true)
        case .disableGalleryCameraPreview:
            SGSimpleSettings.shared.disableGalleryCameraPreview = !value
        case .disableSendAsButton:
            SGSimpleSettings.shared.disableSendAsButton = !value
        case .disableSnapDeletionEffect:
            SGSimpleSettings.shared.disableSnapDeletionEffect = !value
        case .contextShowReport:
            SGSimpleSettings.shared.contextShowReport = value
        case .contextShowReply:
            SGSimpleSettings.shared.contextShowReply = value
        case .contextShowPin:
            SGSimpleSettings.shared.contextShowPin = value
        case .contextShowSaveMedia:
            SGSimpleSettings.shared.contextShowSaveMedia = value
        case .contextShowMessageReplies:
            SGSimpleSettings.shared.contextShowMessageReplies = value
        case .stickerTimestamp:
            SGSimpleSettings.shared.stickerTimestamp = value
        case .contextShowJson:
            SGSimpleSettings.shared.contextShowJson = value
        case .hideRecordingButton:
            SGSimpleSettings.shared.hideRecordingButton = !value
        case .hideTabBar:
            SGSimpleSettings.shared.hideTabBar = value
            simplePromise.set(true) // Trigger update for 'enabled' field of other toggles
            askForRestart?()
        case .showDC:
            SGSimpleSettings.shared.showDC = value
        case .showCreationDate:
            SGSimpleSettings.shared.showCreationDate = value
        case .showRegDate:
            SGSimpleSettings.shared.showRegDate = value
        case .compactChatList:
            SGSimpleSettings.shared.compactChatList = value
            askForRestart?()
        case .compactMessagePreview:
            SGSimpleSettings.shared.chatListLines = value ? SGSimpleSettings.ChatListLines.one.rawValue : SGSimpleSettings.ChatListLines.three.rawValue
            askForRestart?()
        case .compactFolderNames:
            SGSimpleSettings.shared.compactFolderNames = value
            askForRestart?()
        case .allChatsHidden:
            SGSimpleSettings.shared.allChatsHidden = value
            askForRestart?()
        case .defaultEmojisFirst:
            SGSimpleSettings.shared.defaultEmojisFirst = value
        case .messageDoubleTapActionOutgoingEdit:
            SGSimpleSettings.shared.messageDoubleTapActionOutgoing = value ? SGSimpleSettings.MessageDoubleTapAction.edit.rawValue : SGSimpleSettings.MessageDoubleTapAction.default.rawValue
        case .wideChannelPosts:
            SGSimpleSettings.shared.wideChannelPosts = value
        case .forceEmojiTab:
            SGSimpleSettings.shared.forceEmojiTab = value
        case .forceBuiltInMic:
            SGSimpleSettings.shared.forceBuiltInMic = value
        case .hideChannelBottomButton:
            SGSimpleSettings.shared.hideChannelBottomButton = !value
        case .secondsInMessages:
            SGSimpleSettings.shared.secondsInMessages = value
        case .confirmCalls:
            SGSimpleSettings.shared.confirmCalls = value
        case .swipeForVideoPIP:
            SGSimpleSettings.shared.videoPIPSwipeDirection = value ? SGSimpleSettings.VideoPIPSwipeDirection.up.rawValue : SGSimpleSettings.VideoPIPSwipeDirection.none.rawValue
        case .enableVoipTcp:
            let _ = (
                updateExperimentalUISettingsInteractively(accountManager: context.sharedContext.accountManager, { settings in
                        var settings = settings
                        settings.enableVoipTcp = value
                        return settings
                    }
                )
            ).start()
        case .nyStyleSnow:
            SGSimpleSettings.shared.nyStyle = value ? SGSimpleSettings.NYStyle.snow.rawValue : SGSimpleSettings.NYStyle.default.rawValue
            simplePromise.set(true) // Trigger update for 'enabled' field of other toggles
        case .nyStyleLightning:
            SGSimpleSettings.shared.nyStyle = value ? SGSimpleSettings.NYStyle.lightning.rawValue : SGSimpleSettings.NYStyle.default.rawValue
            simplePromise.set(true) // Trigger update for 'enabled' field of other toggles
        case .combinedMediaViewer:
            SGSimpleSettings.shared.combinedMediaViewer = value
        case .videoControlsInFooter:
            SGSimpleSettings.shared.videoControlsInFooter = value
        case .hideAccountInNotifications:
            SGSimpleSettings.shared.hideAccountInNotifications = value
            SGSimpleSettings.shared.synchronizeShared()
        // MARK: Ugram
        case .ugramSaveDeletedMessages:
            UgramSettings.shared.setBool(value, for: "ugramSaveDeletedMessages")
            simplePromise.set(true) // "Mark deleted" depends on it
        case .ugramMarkDeletedMessages:
            UgramSettings.shared.setBool(value, for: "ugramMarkDeletedMessages")
        case .ugramKeepSelfDestructingMedia:
            UgramSettings.shared.setBool(value, for: "ugramKeepSelfDestructingMedia")
        case .ugramNoReadReceipts:
            UgramSettings.shared.setBool(value, for: "ugramNoReadReceipts")
        case .ugramNoTyping:
            UgramSettings.shared.setBool(value, for: "ugramNoTyping")
        case .ugramHideOnline:
            UgramSettings.shared.setBool(value, for: "ugramHideOnline")
        case .ugramDisableAutoDownload:
            UgramSettings.shared.setBool(value, for: "ugramDisableAutoDownload")
        case .ugramBackgroundNotifications:
            UgramSettings.shared.setBool(value, for: "ugramBackgroundNotifications")
        case .ugramInstantPush:
            UgramSettings.shared.setBool(value, for: "ugramInstantPush")
            let presentationData = context.sharedContext.currentPresentationData.with { $0 }
            ugramUpdateInstantPush(context: context, enabled: value, isRussian: presentationData.strings.baseLanguageCode == "ru")
        case .ugramAutoApproveJoinRequests:
            UgramSettings.shared.setBool(value, for: "ugramAutoApproveJoinRequests")
        case .ugramEditHistory:
            UgramSettings.shared.setBool(value, for: "ugramEditHistory")
        case .ugramHeartEffect:
            UgramSettings.shared.setBool(value, for: "ugramHeartEffect")
        case .ugramAutoSticker:
            UgramSettings.shared.setBool(value, for: "ugramAutoSticker")
        case .ugramUnlimitedPins:
            UgramSettings.shared.setBool(value, for: "ugramUnlimitedPins")
        }
    }, updateSliderValue: { setting, value in
        switch (setting) {
            case .accountColorsSaturation:
                if SGSimpleSettings.shared.accountColorsSaturation != value {
                    SGSimpleSettings.shared.accountColorsSaturation = value
                    simplePromise.set(true)
                }
            case .outgoingPhotoQuality:
                if SGSimpleSettings.shared.outgoingPhotoQuality != value {
                    SGSimpleSettings.shared.outgoingPhotoQuality = value
                    simplePromise.set(true)
                }
            case .stickerSize:
                if SGSimpleSettings.shared.stickerSize != value {
                    SGSimpleSettings.shared.stickerSize = value
                    simplePromise.set(true)
                }
        }

    }, setOneFromManyValue: { setting in
        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        var options: [SGOneFromManyOption] = []
        
        // MARK: Ugram
        let isRussian = presentationData.strings.baseLanguageCode == "ru"
        switch setting {
        case .ugramAutoPostfix:
            let prompt = promptController(context: context, text: isRussian ? "Авто-постфикс" : "Auto-postfix", subtitle: isRussian ? "Текст добавится в конец каждого вашего сообщения. Оставьте пустым, чтобы отключить." : "This text is added to the end of each of your messages. Leave empty to turn off.", value: UgramSettings.shared.string("ugramAutoPostfix") ?? "", placeholder: isRussian ? "Например: — отправлено из Ugram" : "For example: sent from Ugram", characterLimit: 200, displayCharacterLimit: true, apply: { value in
                UgramSettings.shared.setString(value?.trimmingCharacters(in: .whitespacesAndNewlines), for: "ugramAutoPostfix")
                simplePromise.set(true)
            })
            presentControllerImpl?(prompt, nil)
            return
        case .ugramRecommended:
            let ugram = UgramSettings.shared
            for key in ["ugramSaveDeletedMessages", "ugramMarkDeletedMessages", "ugramKeepSelfDestructingMedia", "ugramEditHistory", "ugramUnlimitedPins"] {
                ugram.setBool(true, for: key)
            }
            SGSimpleSettings.shared.storyStealthMode = true
            simplePromise.set(true)
            presentControllerImpl?(UndoOverlayController(presentationData: presentationData, content: .info(title: nil, text: isRussian ? "Рекомендуемые функции включены." : "Recommended features are on.", timeout: nil, customUndoText: nil), elevatedLayout: false, action: { _ in return true }), nil)
            return
        case .ugramNtfySubscribe:
            ugramOpenNtfy(context: context)
            return
        case .ugramAdminFolders:
            let _ = (ugramUpdateAdminFolders(account: context.account, groupsTitle: isRussian ? "Мои группы" : "My groups", channelsTitle: isRussian ? "Мои каналы" : "My channels")
            |> deliverOnMainQueue).start(next: { result in
                var text: String
                if result.groups == 0 && result.channels == 0 {
                    text = isRussian ? "Не нашлось групп и каналов, где вы администратор." : "No groups or channels you administer were found."
                } else {
                    text = isRussian ? "Готово: групп — \(result.groups), каналов — \(result.channels)." : "Done: \(result.groups) groups, \(result.channels) channels."
                }
                if !result.createdAll {
                    text += isRussian ? " Не все папки созданы: достигнут лимит папок." : " Not all folders were created: the folder limit was reached."
                }
                presentControllerImpl?(UndoOverlayController(presentationData: presentationData, content: .info(title: nil, text: text, timeout: nil, customUndoText: nil), elevatedLayout: false, action: { _ in return true }), nil)
            })
            return
        default:
            break
        }

        switch (setting) {
            case .ugramAutoPostfix, .ugramAdminFolders, .ugramRecommended:
                break
            case .ugramNtfySubscribe:
                break
            case .ugramIslandBadge:
                let current = SGSimpleSettings.shared.customAppBadge
                for badge in ugramIslandBadges {
                    options.append(SGOneFromManyOption(title: isRussian ? badge.ru : badge.en, isSelected: current == badge.value, action: {
                        SGSimpleSettings.shared.customAppBadge = badge.value
                        if let badgeView = context.sharedContext.mainWindow?.badgeView {
                            if badge.value == "hidden" {
                                badgeView.isHidden = true
                            } else {
                                badgeView.image = UIImage(bundleImageName: badge.value.isEmpty ? "Components/AppBadge" : badge.value) ?? UIImage(bundleImageName: "Components/AppBadge")
                                badgeView.isHidden = false
                            }
                        }
                        simplePromise.set(true)
                    }))
                }
            case .ugramUnreadReminder:
                let current = UgramSettings.shared.int("ugramUnreadReminderHours", default: 0)
                for hours in ugramReminderHours {
                    options.append(SGOneFromManyOption(title: ugramReminderTitle(hours, isRussian: isRussian), isSelected: current == hours, action: {
                        UgramSettings.shared.setInt(hours, for: "ugramUnreadReminderHours")
                        simplePromise.set(true)
                    }))
                }
            case .ugramTextStyle:
                for style in ugramTextStyles {
                    options.append(SGOneFromManyOption(title: isRussian ? style.ru : style.en, isSelected: (UgramSettings.shared.string("ugramTextStyle") ?? "") == style.value, action: {
                        UgramSettings.shared.setString(style.value, for: "ugramTextStyle")
                        simplePromise.set(true)
                    }))
                }
            case .downloadSpeedBoost:
                let setAction: (String) -> Void = { value in
                    SGSimpleSettings.shared.downloadSpeedBoost = value
                    
                    let enableDownloadX: Bool
                    switch (value) {
                        case SGSimpleSettings.DownloadSpeedBoostValues.none.rawValue:
                            enableDownloadX = false
                        default:
                            enableDownloadX = true
                    }
                    
                    // Updating controller
                    simplePromise.set(true)

                    let _ = updateNetworkSettingsInteractively(postbox: context.account.postbox, network: context.account.network, { settings in
                        var settings = settings
                        settings.useExperimentalDownload = enableDownloadX
                        return settings
                    }).start(completed: {
                        Queue.mainQueue().async {
                            askForRestart?()
                        }
                    })
                }

                for value in SGSimpleSettings.DownloadSpeedBoostValues.allCases {
                    options.append(SGOneFromManyOption(title: i18n("Settings.DownloadsBoost.\(value.rawValue)", presentationData.strings.baseLanguageCode), isSelected: SGSimpleSettings.shared.downloadSpeedBoost == value.rawValue, action: {
                        setAction(value.rawValue)
                    }))
                }
            case .bottomTabStyle:
                let setAction: (String) -> Void = { value in
                    SGSimpleSettings.shared.bottomTabStyle = value
                    simplePromise.set(true)
                }

                for value in SGSimpleSettings.BottomTabStyleValues.allCases {
                    options.append(SGOneFromManyOption(title: i18n("Settings.Folders.BottomTabStyle.\(value.rawValue)", presentationData.strings.baseLanguageCode), isSelected: SGSimpleSettings.shared.bottomTabStyle == value.rawValue, action: {
                        setAction(value.rawValue)
                    }))
                }
            case .allChatsTitleLengthOverride:
                let setAction: (String) -> Void = { value in
                    SGSimpleSettings.shared.allChatsTitleLengthOverride = value
                    simplePromise.set(true)
                }

                for value in SGSimpleSettings.AllChatsTitleLengthOverride.allCases {
                    let title: String
                    switch (value) {
                        case SGSimpleSettings.AllChatsTitleLengthOverride.short:
                            title = "\"\(presentationData.strings.ChatList_Tabs_All)\""
                        case SGSimpleSettings.AllChatsTitleLengthOverride.long:
                            title = "\"\(presentationData.strings.ChatList_Tabs_AllChats)\""
                        default:
                            title = i18n("Settings.Folders.AllChatsTitle.none", presentationData.strings.baseLanguageCode)
                    }
                    options.append(SGOneFromManyOption(title: title, isSelected: SGSimpleSettings.shared.allChatsTitleLengthOverride == value.rawValue, action: {
                        setAction(value.rawValue)
                    }))
                }
//        case .allChatsFolderPositionOverride:
//            let setAction: (String) -> Void = { value in
//                SGSimpleSettings.shared.allChatsFolderPositionOverride = value
//                simplePromise.set(true)
//            }
//
//            for value in SGSimpleSettings.AllChatsFolderPositionOverride.allCases {
//                items.append(ActionSheetButtonItem(title: i18n("Settings.Folders.AllChatsTitle.\(value)", presentationData.strings.baseLanguageCode), color: .accent, action: { [weak actionSheet] in
//                    actionSheet?.dismissAnimated()
//                    setAction(value.rawValue)
//                }))
//            }
            case .translationBackend:
                let setAction: (String) -> Void = { value in
                    SGSimpleSettings.shared.translationBackend = value
                    simplePromise.set(true)
                }

                for value in SGSimpleSettings.TranslationBackend.allCases {
                    if value == .system {
                        if #available(iOS 18.0, *) {
                        } else {
                            continue // System translation is not available on iOS 17 and below
                        }
                    }
                    options.append(SGOneFromManyOption(title: i18n("Settings.Translation.Backend.\(value.rawValue)", presentationData.strings.baseLanguageCode), isSelected: SGSimpleSettings.shared.translationBackend == value.rawValue, action: {
                        setAction(value.rawValue)
                    }))
                }
            case .transcriptionBackend:
                let setAction: (String) -> Void = { value in
                    SGSimpleSettings.shared.transcriptionBackend = value
                    simplePromise.set(true)
                }

                for value in SGSimpleSettings.TranscriptionBackend.allCases {
                    if #available(iOS 13.0, *) {
                    } else {
                        if value == .apple {
                            continue // Apple recognition is not available on iOS 12
                        }
                    }
                    options.append(SGOneFromManyOption(title: i18n("Settings.Transcription.Backend.\(value.rawValue)", presentationData.strings.baseLanguageCode), isSelected: SGSimpleSettings.shared.transcriptionBackend == value.rawValue, action: {
                        setAction(value.rawValue)
                    }))
                }
            case .nyStyle:
                let setAction: (String) -> Void = { value in
                    SGSimpleSettings.shared.nyStyle = value
                    simplePromise.set(true)
                }

                for value in SGSimpleSettings.NYStyle.allCases {
                    options.append(SGOneFromManyOption(title: i18n("Settings.NY.Style.\(value.rawValue)", presentationData.strings.baseLanguageCode), isSelected: SGSimpleSettings.shared.nyStyle == value.rawValue, action: {
                        setAction(value.rawValue)
                    }))
                }
        }
        
        presentOneFromManyImpl?(setting, options)
    }, openDisclosureLink: { [weak context] link in
        guard let context else {
            return
        }
        switch (link) {
            case .languageSettings:
                pushControllerImpl?(context.sharedContext.makeLocalizationListController(context: context))
            case .contentSettings:
                let _ = (getSGSettingsURL(context: context) |> deliverOnMainQueue).start(next: { [weak context] url in
                    guard let strongContext = context else {
                        return
                    }
                    strongContext.sharedContext.applicationBindings.openUrl(url)
                })
        }
    }, searchInput: { searchQuery in
        updateState { state in
            var updatedState = state
            updatedState.searchQuery = searchQuery
            return updatedState
        }
    })
    
    let sharedData = context.sharedContext.accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.callListSettings, ApplicationSpecificSharedDataKeys.experimentalUISettings])
    let preferences = context.engine.data.subscribe(TelegramEngine.EngineData.Item.Configuration.App())
    let updatedContentSettingsConfiguration = contentSettingsConfiguration(network: context.account.network)
    |> map(Optional.init)
    let contentSettingsConfiguration = Promise<ContentSettingsConfiguration?>()
    contentSettingsConfiguration.set(.single(nil)
    |> then(updatedContentSettingsConfiguration))
    
    let signal = combineLatest(simplePromise.get(), /*sliderPromise.get(),*/ statePromise.get(), context.sharedContext.presentationData, sharedData, preferences, contentSettingsConfiguration.get(),
        context.engine.accountData.observeAvailableColorOptions(scope: .replies),
        context.engine.accountData.observeAvailableColorOptions(scope: .profile)
    )
    |> map { _, /*sliderValue,*/ state, presentationData, sharedData, appConfiguration, contentSettingsConfiguration, availableReplyColors, availableProfileColors ->  (ItemListControllerState, (ItemListNodeState, Any)) in
        
        let callListSettings: CallListSettings = sharedData.entries[ApplicationSpecificSharedDataKeys.callListSettings]?.get(CallListSettings.self) ?? CallListSettings.defaultSettings
        let experimentalUISettings: ExperimentalUISettings = sharedData.entries[ApplicationSpecificSharedDataKeys.experimentalUISettings]?.get(ExperimentalUISettings.self) ?? ExperimentalUISettings.defaultSettings
        
        let entries = SGControllerEntries(presentationData: presentationData, callListSettings: callListSettings, experimentalUISettings: experimentalUISettings, appConfiguration: appConfiguration, nameColors: PeerNameColors.with(availableReplyColors: availableReplyColors, availableProfileColors: availableProfileColors), state: state, page: page)
        
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(page.title(isRussian: presentationData.strings.baseLanguageCode == "ru")), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        
        // TODO(swiftgram): focusOnItemTag support
        /* var index = 0
        var scrollToItem: ListViewScrollToItem?
         if let focusOnItemTag = focusOnItemTag {
            for entry in entries {
                if entry.tag?.isEqual(to: focusOnItemTag) ?? false {
                    scrollToItem = ListViewScrollToItem(index: index, position: .top(0.0), animated: false, curve: .Default(duration: 0.0), directionHint: .Up)
                }
                index += 1
            }
        } */
        
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: entries, style: .blocks, ensureVisibleItemTag: /*focusOnItemTag*/ nil, initialScrollToItem: nil /* scrollToItem*/ )
        
        return (controllerState, (listState, arguments))
    }
    
    let controller = ItemListController(context: context, state: signal)
    presentOneFromManyImpl = { [weak controller] setting, options in
        guard let controller else {
            return
        }
        sgPresentOneFromManySelector(controller: controller, setting: setting, presentationData: context.sharedContext.currentPresentationData.with { $0 }, options: options)
    }
    presentControllerImpl = { [weak controller] c, a in
        controller?.present(c, in: .window(.root), with: a)
    }
    pushControllerImpl = { [weak controller] c in
        (controller?.navigationController as? NavigationController)?.pushViewController(c)
    }
//    getRootControllerImpl = { [weak controller] in
//        return controller?.view.window?.rootViewController
//    }
//    getNavigationControllerImpl = { [weak controller] in
//        return controller?.navigationController as? NavigationController
//    }
    askForRestart = { [weak context] in
        guard let context = context else {
            return
        }
        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        presentControllerImpl?(
            UndoOverlayController(
                presentationData: presentationData, 
                content: .info(title: nil, // i18n("Common.RestartRequired", presentationData.strings.baseLanguageCode),
                    text: i18n("Common.RestartRequired", presentationData.strings.baseLanguageCode),
                    timeout: nil,
                    customUndoText: i18n("Common.RestartNow", presentationData.strings.baseLanguageCode) //presentationData.strings.Common_Yes
                ),
                elevatedLayout: false,
                action: { action in if action == .undo { exit(0) }; return true }
            ),
            nil
        )
    }
    return controller

}
