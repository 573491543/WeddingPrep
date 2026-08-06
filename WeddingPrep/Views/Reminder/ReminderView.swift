import SwiftUI
import SwiftData

struct ReminderView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [WeddingProfile]
    @Query private var tasks: [TaskItem]

    private var weddingDate: Date {
        profiles.first?.weddingDate ?? Date()
    }

    // Pending (not completed, not overdue)
    private var pendingTasks: [TaskItem] {
        tasks.filter { !$0.isCompleted && !$0.isOverdue(weddingDate: weddingDate) }
            .sorted { $0.daysBeforeWedding > $1.daysBeforeWedding }
    }

    // Overdue (not completed, overdue)
    private var overdueTasks: [TaskItem] {
        tasks.filter { $0.isOverdue(weddingDate: weddingDate) }
            .sorted { $0.daysBeforeWedding > $1.daysBeforeWedding }
    }

    // Completed
    private var completedTasks: [TaskItem] {
        tasks.filter { $0.isCompleted }
            .sorted { ($0.completedDate ?? Date()) > ($1.completedDate ?? Date()) }
    }

    // Group pending tasks by time
    private var thisWeekTasks: [TaskItem] {
        pendingTasks.filter { task in
            let due = task.dueDate(weddingDate: weddingDate)
            return DateHelper.TimeGroup.group(for: due) == .thisWeek
        }
    }

    private var thisMonthTasks: [TaskItem] {
        pendingTasks.filter { task in
            let due = task.dueDate(weddingDate: weddingDate)
            return DateHelper.TimeGroup.group(for: due) == .thisMonth
        }
    }

    private var laterTasks: [TaskItem] {
        pendingTasks.filter { task in
            let due = task.dueDate(weddingDate: weddingDate)
            return DateHelper.TimeGroup.group(for: due) == .later
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.sectionSpacing) {
                    // Status stats
                    statsBar

                    // Overdue section (if any)
                    if !overdueTasks.isEmpty {
                        overdueSection
                    }

                    // This week
                    if !thisWeekTasks.isEmpty {
                        reminderSection(title: "本周内", tasks: thisWeekTasks)
                    }

                    // This month
                    if !thisMonthTasks.isEmpty {
                        reminderSection(title: "本月内", tasks: thisMonthTasks)
                    }

                    // Later
                    if !laterTasks.isEmpty {
                        reminderSection(title: "更远", tasks: laterTasks)
                    }

                    // Completed
                    if !completedTasks.isEmpty {
                        completedSection
                    }

                    // Empty state
                    if pendingTasks.isEmpty && overdueTasks.isEmpty && completedTasks.isEmpty {
                        EmptyStateView(icon: "bell.slash", title: "暂无提醒", subtitle: "添加任务后将自动出现在这里")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
            .background(AppTheme.bg)
            .navigationTitle("提醒中心")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Stats Bar
    private var statsBar: some View {
        HStack(spacing: 12) {
            statItem(count: pendingTasks.count, label: "待提醒", color: AppTheme.primaryColor)
            statItem(count: overdueTasks.count, label: "已逾期", color: AppTheme.dangerColor)
            statItem(count: completedTasks.count, label: "已完成", color: AppTheme.successColor)
        }
    }

    private func statItem(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(AppTheme.title)
                .foregroundColor(color)
            Text(label)
                .font(AppTheme.smallCaption)
                .foregroundColor(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius)
                .fill(color.opacity(0.08))
        )
    }

    // MARK: - Sections
    private var overdueSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(AppTheme.dangerColor)
                Text("已逾期")
                    .font(AppTheme.headline)
                    .foregroundColor(AppTheme.dangerColor)
                Spacer()
                Text("\(overdueTasks.count) 项")
                    .font(AppTheme.smallCaption)
                    .foregroundColor(AppTheme.secondaryText)
            }

            ForEach(overdueTasks, id: \.id) { task in
                ReminderRowView(task: task, weddingDate: weddingDate, isOverdue: true) {
                    toggleTask(task)
                }
            }
        }
    }

    private func reminderSection(title: String, tasks: [TaskItem]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(AppTheme.headline)
                    .foregroundColor(AppTheme.primaryText)
                Spacer()
                Text("\(tasks.count) 项")
                    .font(AppTheme.smallCaption)
                    .foregroundColor(AppTheme.secondaryText)
            }

            ForEach(tasks, id: \.id) { task in
                ReminderRowView(task: task, weddingDate: weddingDate, isOverdue: false) {
                    toggleTask(task)
                }
            }
        }
    }

    private var completedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AppTheme.successColor)
                Text("已完成")
                    .font(AppTheme.headline)
                    .foregroundColor(AppTheme.primaryText)
                Spacer()
                Text("\(completedTasks.count) 项")
                    .font(AppTheme.smallCaption)
                    .foregroundColor(AppTheme.secondaryText)
            }

            ForEach(completedTasks, id: \.id) { task in
                ReminderRowView(task: task, weddingDate: weddingDate, isOverdue: false) {
                    toggleTask(task)
                }
            }
        }
    }

    private func toggleTask(_ task: TaskItem) {
        task.isCompleted.toggle()
        task.completedDate = task.isCompleted ? Date() : nil
        task.updatedAt = Date()
        try? modelContext.save()

        // 完成时取消通知，取消完成时重新安排通知
        if task.isCompleted {
            NotificationManager.cancelNotification(id: task.id.uuidString)
        } else if task.reminderDaysBefore > 0 {
            let dueDate = task.dueDate(weddingDate: weddingDate)
            let notificationDate = Calendar.current.date(
                byAdding: .day, value: -task.reminderDaysBefore, to: dueDate
            ) ?? dueDate
            if notificationDate > Date() {
                NotificationManager.scheduleNotification(
                    id: task.id.uuidString,
                    title: "备婚提醒",
                    body: "「\(task.title)」还有\(task.reminderDaysBefore)天到期",
                    triggerDate: notificationDate
                )
            }
        }
    }
}

// MARK: - Reminder Row
private struct ReminderRowView: View {
    let task: TaskItem
    let weddingDate: Date
    let isOverdue: Bool
    let onToggle: () -> Void

    private var dueDate: Date {
        task.dueDate(weddingDate: weddingDate)
    }

    private var countdownText: String {
        task.countdownText(weddingDate: weddingDate)
    }

    var body: some View {
        Button {
            onToggle()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(task.isCompleted ? AppTheme.successColor : (isOverdue ? AppTheme.dangerColor : AppTheme.secondaryText.opacity(0.4)))

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        TagView(
                            text: task.type,
                            color: (task.type == TaskType.task.rawValue ? AppTheme.infoColor : AppTheme.warningColor).opacity(0.15),
                            textColor: task.type == TaskType.task.rawValue ? AppTheme.infoColor : AppTheme.warningColor
                        )
                        Text(task.title)
                            .font(AppTheme.body)
                            .foregroundColor(task.isCompleted ? AppTheme.secondaryText : AppTheme.primaryText)
                            .strikethrough(task.isCompleted)
                    }

                    HStack(spacing: 8) {
                        if task.isCompleted {
                            Text("已完成")
                                .font(AppTheme.smallCaption)
                                .foregroundColor(AppTheme.successColor)
                        } else if isOverdue {
                            Text(countdownText)
                                .font(AppTheme.smallCaption)
                                .foregroundColor(AppTheme.dangerColor)
                                .fontWeight(.medium)
                        } else {
                            Text(countdownText)
                                .font(AppTheme.smallCaption)
                                .foregroundColor(AppTheme.accentColor)
                                .fontWeight(.medium)
                        }

                        Text(DateHelper.formatShortDate(dueDate))
                            .font(AppTheme.smallCaption)
                            .foregroundColor(AppTheme.secondaryText)

                        if task.reminderDaysBefore > 0 && !task.isCompleted {
                            Text("提前\(task.reminderDaysBefore)天")
                                .font(AppTheme.smallCaption)
                                .foregroundColor(AppTheme.secondaryText.opacity(0.7))
                        }
                    }

                    if !task.notes.isEmpty {
                        Text(task.notes)
                            .font(AppTheme.smallCaption)
                            .foregroundColor(AppTheme.secondaryText.opacity(0.8))
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius)
                    .fill(AppTheme.cardBg)
                    .overlay {
                        if isOverdue {
                            RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius)
                                .fill(AppTheme.dangerColor)
                                .opacity(0.05)
                        }
                    }
                    .overlay {
                        if isOverdue {
                            RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius)
                                .stroke(AppTheme.dangerColor, lineWidth: 1)
                                .opacity(0.12)
                        }
                    }
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
