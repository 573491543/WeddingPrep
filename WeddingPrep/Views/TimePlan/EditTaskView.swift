import SwiftUI
import SwiftData

struct EditTaskView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [WeddingProfile]

    var task: TaskItem?

    @State private var title = ""
    @State private var stage = TaskStage.oneMonthBefore
    @State private var category = TaskCategory.other
    @State private var type = TaskType.task
    @State private var priority = Priority.medium
    @State private var daysBeforeWedding = 30
    @State private var reminderDaysBefore = 3
    @State private var notes = ""
    @State private var isCompleted = false

    private var weddingDate: Date {
        profiles.first?.weddingDate ?? Date()
    }

    private var dueDate: Date {
        DateHelper.dueDate(weddingDate: weddingDate, daysBeforeWedding: daysBeforeWedding)
    }

    private var isEditing: Bool {
        task != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("任务信息") {
                    TextField("任务标题", text: $title)
                    Picker("时间节点", selection: $stage) {
                        ForEach(TaskStage.allCases, id: \.self) { stage in
                            Text(stage.rawValue).tag(stage)
                        }
                    }
                    Picker("任务类别", selection: $category) {
                        ForEach(TaskCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                    Picker("任务类型", selection: $type) {
                        ForEach(TaskType.allCases, id: \.self) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                    Picker("优先级", selection: $priority) {
                        ForEach(Priority.allCases, id: \.self) { p in
                            HStack {
                                Circle().fill(p.color).frame(width: 8, height: 8)
                                Text(p.label)
                            }.tag(p)
                        }
                    }
                }

                Section("时间设置") {
                    Stepper("距婚礼 \(daysBeforeWedding) 天", value: $daysBeforeWedding, in: 0...365, step: 1)
                        .onChange(of: stage) { _, newStage in
                            daysBeforeWedding = newStage.defaultDaysBefore
                        }

                    Text("截止日期：\(DateHelper.formatChineseDate(dueDate))")
                        .font(AppTheme.caption)
                        .foregroundColor(AppTheme.secondaryText)

                    Stepper("提前 \(reminderDaysBefore) 天提醒", value: $reminderDaysBefore, in: 0...30, step: 1)
                }

                Section("备注") {
                    TextField("补充说明...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                if isEditing {
                    Section {
                        Toggle("已完成", isOn: $isCompleted)
                    }
                }

                Section {
                    Button(isEditing ? "保存修改" : "添加任务") {
                        saveTask()
                    }
                    .font(AppTheme.headline)
                    .foregroundColor(AppTheme.primaryColor)
                    .frame(maxWidth: .infinity)
                    .disabled(title.isEmpty)

                    if isEditing {
                        Button("删除任务", role: .destructive) {
                            deleteTask()
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle(isEditing ? "编辑任务" : "新增任务")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .onAppear {
                loadTask()
            }
        }
    }

    private func loadTask() {
        guard let task else { return }
        title = task.title
        stage = TaskStage(rawValue: task.stage) ?? .oneMonthBefore
        category = TaskCategory(rawValue: task.category) ?? .other
        type = TaskType(rawValue: task.type) ?? .task
        priority = Priority(rawValue: task.priority) ?? .medium
        daysBeforeWedding = task.daysBeforeWedding
        reminderDaysBefore = task.reminderDaysBefore
        notes = task.notes
        isCompleted = task.isCompleted
    }

    private func saveTask() {
        let taskId: UUID
        if let task {
            // Update existing
            task.title = title
            task.stage = stage.rawValue
            task.category = category.rawValue
            task.type = type.rawValue
            task.priority = priority.rawValue
            task.daysBeforeWedding = daysBeforeWedding
            task.reminderDaysBefore = reminderDaysBefore
            task.notes = notes
            task.isCompleted = isCompleted
            task.completedDate = isCompleted ? (task.completedDate ?? Date()) : nil
            task.updatedAt = Date()
            taskId = task.id
        } else {
            // Create new
            let newTask = TaskItem(
                title: title,
                stage: stage.rawValue,
                category: category.rawValue,
                type: type.rawValue,
                daysBeforeWedding: daysBeforeWedding,
                priority: priority.rawValue,
                isCompleted: false,
                notes: notes,
                reminderDaysBefore: reminderDaysBefore
            )
            modelContext.insert(newTask)
            taskId = newTask.id
        }
        try? modelContext.save()

        // 更新通知
        NotificationManager.cancelNotification(id: taskId.uuidString)
        if !isCompleted && reminderDaysBefore > 0 {
            let due = dueDate
            let notificationDate = Calendar.current.date(
                byAdding: .day, value: -reminderDaysBefore, to: due
            ) ?? due
            if notificationDate > Date() {
                NotificationManager.scheduleNotification(
                    id: taskId.uuidString,
                    title: "备婚提醒",
                    body: "「\(title)」还有\(reminderDaysBefore)天到期",
                    triggerDate: notificationDate
                )
            }
        }

        dismiss()
    }

    private func deleteTask() {
        guard let task else { return }
        NotificationManager.cancelNotification(id: task.id.uuidString)
        modelContext.delete(task)
        try? modelContext.save()
        dismiss()
    }
}
