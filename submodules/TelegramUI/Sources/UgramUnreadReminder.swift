// MARK: Ugram - a local notification when unread messages are left after leaving the app.
import Foundation
import UIKit
import UserNotifications
import UgramSettings

enum UgramUnreadReminder {
    private static let identifier = "ugram.unreadReminder"

    static func schedule() {
        let hours = UgramSettings.shared.int("ugramUnreadReminderHours", default: 0)
        let count = UIApplication.shared.applicationIconBadgeNumber
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [self.identifier])
        guard hours > 0, count > 0 else {
            return
        }
        let isRussian = (Locale.preferredLanguages.first ?? "").hasPrefix("ru")
        let content = UNMutableNotificationContent()
        content.title = "Shadowgram"
        content.body = isRussian ? "Непрочитанных сообщений: \(count). Загляните, пока не забыли." : "You have \(count) unread messages."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(hours * 60 * 60), repeats: false)
        center.add(UNNotificationRequest(identifier: self.identifier, content: content, trigger: trigger), withCompletionHandler: nil)
    }

    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [self.identifier])
    }
}
