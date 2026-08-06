import Foundation
import SwiftData

@Model
final class TaskItem {
    var id: UUID
    var title: String
    var stage: String        // TaskStage.rawValue
    var category: String     // TaskCategory.rawValue
    var type: String         // TaskType.rawValue
    var daysBeforeWedding: Int  // 距婚礼天数，核心字段
    var priority: Int        // 0=高 1=中 2=低
    var isCompleted: Bool
    var notes: String
    var reminderDaysBefore: Int  // 提前提醒天数
    var completedDate: Date?
    var createdAt: Date
    var updatedAt: Date

    init(
        title: String,
        stage: String = TaskStage.oneMonthBefore.rawValue,
        category: String = TaskCategory.other.rawValue,
        type: String = TaskType.task.rawValue,
        daysBeforeWedding: Int = 30,
        priority: Int = Priority.medium.rawValue,
        isCompleted: Bool = false,
        notes: String = "",
        reminderDaysBefore: Int = 3
    ) {
        self.id = UUID()
        self.title = title
        self.stage = stage
        self.category = category
        self.type = type
        self.daysBeforeWedding = daysBeforeWedding
        self.priority = priority
        self.isCompleted = isCompleted
        self.notes = notes
        self.reminderDaysBefore = reminderDaysBefore
        self.completedDate = nil
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Computed Properties

    /// 根据婚礼日期计算任务的截止日期
    func dueDate(weddingDate: Date) -> Date {
        Calendar.current.date(byAdding: .day, value: -daysBeforeWedding, to: weddingDate) ?? weddingDate
    }

    /// 距今天数（正数=未来，0=今天，负数=已过）
    func daysFromToday(weddingDate: Date) -> Int {
        let due = dueDate(weddingDate: weddingDate)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dueDay = calendar.startOfDay(for: due)
        let diff = calendar.dateComponents([.day], from: today, to: dueDay).day ?? 0
        return diff
    }

    /// 倒计时文本
    func countdownText(weddingDate: Date) -> String {
        let days = daysFromToday(weddingDate: weddingDate)
        if days > 0 {
            return "\(days)天后"
        } else if days == 0 {
            return "今天"
        } else {
            return "已逾期\(-days)天"
        }
    }

    /// 是否已逾期（需要传入婚礼日期）
    func isOverdue(weddingDate: Date) -> Bool {
        if isCompleted { return false }
        return daysFromToday(weddingDate: weddingDate) < 0
    }

    /// 优先级枚举
    var priorityEnum: Priority {
        Priority(rawValue: priority) ?? .medium
    }
}
