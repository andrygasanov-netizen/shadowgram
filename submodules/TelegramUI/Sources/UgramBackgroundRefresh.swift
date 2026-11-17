// MARK: Ugram - notifications without push: iOS wakes the app now and then, it syncs and reports new unread messages.
import Foundation
import UIKit
import UserNotifications
import BackgroundTasks
import UgramSettings

@available(iOS 13.0, *)
enum UgramBackgroundRefresh {
    static let settingKey = "ugramBackgroundNotifications"
    private static let lastCountKey = "ugramBackgroundLastUnread"
    private static let notificationId = "ugram.backgroundUnread"

    static var isEnabled: Bool {
        return UgramSettings.shared.bool(self.settingKey, default: false)
    }

    static func identifier() -> String {
        return "\(Bundle.main.bundleIdentifier ?? "").refresh"
    }

    /// Asks iOS for the next wake-up. iOS decides the actual time (usually 15 minutes to a few hours).
    static func schedule() {
        let identifier = self.identifier()
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: identifier)
        guard self.isEnabled else {
            return
        }
        let request = BGAppRefreshTaskRequest(identifier: identifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
        }
    }

    /// The unread count the user already knows about (when leaving the app, or the last notification).
    static func rememberCurrentCount(_ count: Int) {
        UgramSettings.shared.setInt(count, for: self.lastCountKey)
    }

    static func clearNotification() {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [self.notificationId])
    }

    /// Called after a background sync with the fresh unread count.
    static func report(count: Int) {
        let last = UgramSettings.shared.int(self.lastCountKey, default: 0)
        self.rememberCurrentCount(count)
        guard count > last else {
            return
        }
        let isRussian = (Locale.preferredLanguages.first ?? "").hasPrefix("ru")
        let content = UNMutableNotificationContent()
        content.title = "Shadowgram"
        let newCount = count - last
        content.body = isRussian ? "Новых сообщений: \(newCount). Всего непрочитанных: \(count)." : "New messages: \(newCount). Unread in total: \(count)."
        content.sound = .default
        content.badge = NSNumber(value: count)
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: self.notificationId, content: content, trigger: nil), withCompletionHandler: nil)
    }
}
