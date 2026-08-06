import Foundation
import UserNotifications

// MARK: - NotificationManager (本地通知管理)
enum NotificationManager {

    /// 请求通知权限
    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            if granted {
                print("Notification permission granted")
            } else {
                print("Notification permission denied")
            }
        }
    }

    /// 为所有未完成的任务安排通知
    static func scheduleAllTaskNotifications(tasks: [TaskItem], weddingDate: Date) {
        // Cancel all existing notifications first
        cancelAllNotifications()

        for task in tasks where !task.isCompleted && task.reminderDaysBefore > 0 {
            // Calculate notification trigger date
            let dueDate = task.dueDate(weddingDate: weddingDate)
            let notificationDate = Calendar.current.date(
                byAdding: .day,
                value: -task.reminderDaysBefore,
                to: dueDate
            ) ?? dueDate

            // Only schedule future notifications
            if notificationDate > Date() {
                scheduleNotification(
                    id: task.id.uuidString,
                    title: "备婚提醒",
                    body: "「\(task.title)」还有\(task.reminderDaysBefore)天到期",
                    triggerDate: notificationDate
                )
            }
        }
    }

    /// 安排单条通知
    static func scheduleNotification(
        id: String,
        title: String,
        body: String,
        triggerDate: Date
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1

        let calendar = Calendar.current
        let components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: triggerDate
        )

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("Failed to schedule notification: \(error.localizedDescription)")
            }
        }
    }

    /// 取消单条通知
    static func cancelNotification(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }

    /// 取消所有通知
    static func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    /// 婚礼倒计时通知（定期提醒）
    static func scheduleWeddingCountdown(weddingDate: Date) {
        let daysLeft = DateHelper.daysUntilWedding(weddingDate: weddingDate)
        guard daysLeft > 7 else { return }

        // 每7-30天安排一次倒计时通知
        let interval = min(max(daysLeft / 4, 7), 30)
        var triggerDate = Calendar.current.date(byAdding: .day, value: interval, to: Date()) ?? Date()
        triggerDate = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: triggerDate) ?? triggerDate

        let calendar = Calendar.current
        let weddingDay = calendar.startOfDay(for: weddingDate)

        var index = 0
        while triggerDate < weddingDate {
            // 计算触发日期距婚礼天数（而非当前距婚礼天数）
            let triggerDay = calendar.startOfDay(for: triggerDate)
            let daysAtTrigger = calendar.dateComponents([.day], from: triggerDay, to: weddingDay).day ?? 0

            scheduleNotification(
                id: "wedding_countdown_\(index)",
                title: "婚礼倒计时",
                body: "距离婚礼还有\(max(daysAtTrigger, 0))天，加油备婚！",
                triggerDate: triggerDate
            )

            triggerDate = calendar.date(byAdding: .day, value: interval, to: triggerDate) ?? weddingDate
            index += 1

            // iOS最多允许64条待发送通知，保留部分给任务提醒
            if index >= 30 { break }
        }
    }
}
