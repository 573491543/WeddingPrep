import SwiftUI

struct TaskRowView: View {
    let task: TaskItem
    let weddingDate: Date
    let onToggle: () -> Void
    let onTap: () -> Void

    private var isOverdue: Bool {
        task.isOverdue(weddingDate: weddingDate)
    }

    private var countdownText: String {
        task.countdownText(weddingDate: weddingDate)
    }

    private var dueDate: Date {
        task.dueDate(weddingDate: weddingDate)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // Checkbox
                Button {
                    onToggle()
                } label: {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundColor(task.isCompleted ? AppTheme.successColor : AppTheme.secondaryText.opacity(0.4))
                }
                .buttonStyle(ScaleButtonStyle())

                VStack(alignment: .leading, spacing: 6) {
                    // Title + priority dot
                    HStack(spacing: 6) {
                        if task.priority == Priority.high.rawValue {
                            Circle()
                                .fill(Priority.high.color)
                                .frame(width: 6, height: 6)
                        } else if task.priority == Priority.medium.rawValue {
                            Circle()
                                .fill(Priority.medium.color)
                                .frame(width: 6, height: 6)
                        }
                        Text(task.title)
                            .font(AppTheme.headline)
                            .foregroundColor(task.isCompleted ? AppTheme.secondaryText : AppTheme.primaryText)
                            .strikethrough(task.isCompleted)
                    }

                    // Tags row
                    HStack(spacing: 6) {
                        TagView(text: task.stage, color: AppTheme.secondaryColor.opacity(0.15), textColor: AppTheme.secondaryColor)

                        TagView(text: task.category, color: AppTheme.infoColor.opacity(0.15), textColor: AppTheme.infoColor)

                        if task.type == TaskType.memo.rawValue {
                            TagView(text: "备忘", color: AppTheme.warningColor.opacity(0.15), textColor: AppTheme.warningColor)
                        }
                    }

                    // Countdown + due date
                    HStack(spacing: 8) {
                        if isOverdue {
                            Text(countdownText)
                                .font(AppTheme.smallCaption)
                                .foregroundColor(AppTheme.dangerColor)
                                .fontWeight(.medium)
                        } else if task.isCompleted {
                            Text("已完成")
                                .font(AppTheme.smallCaption)
                                .foregroundColor(AppTheme.successColor)
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

                    // Notes
                    if !task.notes.isEmpty {
                        Text(task.notes)
                            .font(AppTheme.smallCaption)
                            .foregroundColor(AppTheme.secondaryText.opacity(0.8))
                            .lineLimit(2)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(AppTheme.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                    .fill(AppTheme.cardBg)
                    .overlay {
                        if isOverdue {
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                                .fill(AppTheme.dangerColor)
                                .opacity(0.06)
                        }
                    }
                    .overlay {
                        if isOverdue {
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                                .stroke(AppTheme.dangerColor, lineWidth: 1)
                                .opacity(0.15)
                        }
                    }
                    .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
