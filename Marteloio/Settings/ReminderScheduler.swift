import Foundation
import UserNotifications

/// Role: Settings. Local evening reminder. Nothing leaves the device.
@MainActor
enum ReminderScheduler {
    static let identifier = "mrt.evening.reminder"

    static func apply(_ settings: ReminderSettings) async -> String? {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        guard settings.isEnabled else { return nil }

        let granted: Bool
        do {
            granted = try await center.requestAuthorization(options: [.alert, .sound])
        } catch {
            return "The reminder could not ask for permission."
        }
        guard granted else {
            return "Reminders are off in Settings. The toggle stays on this device only."
        }

        let content = UNMutableNotificationContent()
        content.title = "Evening chart"
        content.body = "A few pages still make a rhumb."
        content.sound = .default

        var date = DateComponents()
        date.hour = min(23, max(0, settings.hour))
        date.minute = min(59, max(0, settings.minute))
        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        do {
            try await center.add(request)
            return nil
        } catch {
            return "The evening reminder could not be scheduled."
        }
    }
}
