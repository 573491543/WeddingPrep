import SwiftUI
import SwiftData

struct TimePlanView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [WeddingProfile]
    @Query private var tasks: [TaskItem]

    @State private var searchText = ""
    @State private var selectedStageIndex = 0
    @State private var isTimelineView = false
    @State private var showAddSheet = false
    @State private var editingTask: TaskItem?

    private var weddingDate: Date {
        profiles.first?.weddingDate ?? Date()
    }

    private var stageTitles: [String] {
        ["全部"] + TaskStage.allCases.map { $0.rawValue }
    }

    private var filteredTasks: [TaskItem] {
        var filtered = tasks

        // Stage filter
        if selectedStageIndex > 0 {
            let stage = TaskStage.allCases[selectedStageIndex - 1]
            filtered = filtered.filter { $0.stage == stage.rawValue }
        }

        // Search
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.notes.localizedCaseInsensitiveContains(searchText) ||
                $0.category.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Sort by daysBeforeWedding descending (earlier tasks first)
        filtered.sort { $0.daysBeforeWedding > $1.daysBeforeWedding }
        return filtered
    }

    private var completedCount: Int {
        tasks.filter { $0.isCompleted }.count
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header stats
                headerStats

                // Search bar
                SearchBarView(text: $searchText, placeholder: "搜索任务、备注、分类")
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)

                // Filter chips
                FilterChipScrollView(titles: stageTitles, selectedIndex: $selectedStageIndex)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)

                // View toggle
                viewToggle

                // Task list
                if filteredTasks.isEmpty {
                    EmptyStateView(icon: "calendar.badge.exclamationmark", title: "暂无任务", subtitle: "点击右下角按钮添加任务")
                } else {
                    if isTimelineView {
                        TaskTimelineView(tasks: filteredTasks, weddingDate: weddingDate) { task in
                            editingTask = task
                        }
                    } else {
                        taskListView
                    }
                }
            }
            .background(AppTheme.bg)
            .navigationTitle("时间规划")
            .navigationBarTitleDisplayMode(.inline)
            .overlay(alignment: .bottomTrailing) {
                FloatingActionButton {
                    showAddSheet = true
                }
                .padding(.trailing, 20)
                .padding(.bottom, 40)
            }
            .sheet(isPresented: $showAddSheet) {
                EditTaskView()
            }
            .sheet(item: $editingTask) { task in
                EditTaskView(task: task)
            }
            .onReceive(NotificationCenter.default.publisher(for: .addTask)) { _ in
                showAddSheet = true
            }
        }
    }

    // MARK: - Header Stats
    private var headerStats: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("共 \(tasks.count) 项任务")
                    .font(AppTheme.headline)
                    .foregroundColor(AppTheme.primaryText)
                Text("已完成 \(completedCount) 项")
                    .font(AppTheme.smallCaption)
                    .foregroundColor(AppTheme.secondaryText)
            }
            Spacer()
            if tasks.count > 0 {
                ProgressRingView(
                    progress: Double(completedCount) / Double(tasks.count),
                    lineWidth: 6,
                    color: AppTheme.successColor,
                    centerText: "\(Int(Double(completedCount) / Double(tasks.count) * 100))%"
                )
                .frame(width: 50, height: 50)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - View Toggle
    private var viewToggle: some View {
        HStack(spacing: 0) {
            toggleButton(title: "列表视图", icon: "list.bullet", isSelected: !isTimelineView) {
                isTimelineView = false
            }
            toggleButton(title: "时间轴", icon: "timeline.selection", isSelected: isTimelineView) {
                isTimelineView = true
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius)
                .fill(Color.gray.opacity(0.1))
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private func toggleButton(title: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(AppTheme.smallCaption)
            }
            .foregroundColor(isSelected ? .white : AppTheme.secondaryText)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? AppTheme.primaryColor : Color.clear)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Task List View
    private var taskListView: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(filteredTasks, id: \.id) { task in
                    TaskRowView(task: task, weddingDate: weddingDate) {
                        toggleTask(task)
                    } onTap: {
                        editingTask = task
                    }
                    .contextMenu {
                        Button {
                            editingTask = task
                        } label: {
                            Label("编辑", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            deleteTask(task)
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100)
        }
    }

    // MARK: - Actions
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

    private func deleteTask(_ task: TaskItem) {
        NotificationManager.cancelNotification(id: task.id.uuidString)
        modelContext.delete(task)
        try? modelContext.save()
    }
}
