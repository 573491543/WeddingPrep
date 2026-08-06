import SwiftUI

struct TaskTimelineView: View {
    let tasks: [TaskItem]
    let weddingDate: Date
    var onTaskTap: (TaskItem) -> Void

    private var groupedTasks: [(stage: TaskStage, tasks: [TaskItem])] {
        let stageOrder: [TaskStage] = [
            .sixMonthsBefore, .threeMonthsBefore, .oneMonthBefore, .oneWeekBefore, .weddingDay, .custom
        ]
        return stageOrder.compactMap { stage in
            let stageTasks = tasks.filter { $0.stage == stage.rawValue }
            return stageTasks.isEmpty ? nil : (stage, stageTasks)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(groupedTasks.enumerated()), id: \.offset) { index, group in
                    TimelineSection(stage: group.stage, tasks: group.tasks, weddingDate: weddingDate, onTaskTap: onTaskTap, isLast: index == groupedTasks.count - 1)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100)
        }
    }
}

private struct TimelineSection: View {
    let stage: TaskStage
    let tasks: [TaskItem]
    let weddingDate: Date
    var onTaskTap: (TaskItem) -> Void
    let isLast: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Stage header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(AppTheme.primaryColor.opacity(0.15))
                        .frame(width: 28, height: 28)
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.primaryColor)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(stage.rawValue)
                        .font(AppTheme.headline)
                        .foregroundColor(AppTheme.primaryText)
                    Text("\(tasks.count) 项任务")
                        .font(AppTheme.smallCaption)
                        .foregroundColor(AppTheme.secondaryText)
                }
            }
            .padding(.bottom, 8)

            // Tasks with connecting line
            ForEach(Array(tasks.enumerated()), id: \.element.id) { taskIndex, task in
                HStack(alignment: .top, spacing: 12) {
                    // Timeline line + dot
                    VStack(spacing: 0) {
                        // Line above dot
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 2, height: taskIndex == 0 ? 0 : 12)

                        Circle()
                            .fill(task.isCompleted ? AppTheme.successColor : AppTheme.primaryColor)
                            .frame(width: 10, height: 10)

                        // Line below dot
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 2, height: taskIndex == tasks.count - 1 ? 0 : 30)
                    }

                    // Task card
                    TaskRowView(task: task, weddingDate: weddingDate) {} onTap: {
                        onTaskTap(task)
                    }
                    .padding(.bottom, 8)
                }
            }
        }
        .padding(.bottom, isLast ? 0 : 20)
    }
}
