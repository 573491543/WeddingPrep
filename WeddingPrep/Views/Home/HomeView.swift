import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [WeddingProfile]
    @Query private var tasks: [TaskItem]
    @Query private var expenses: [ExpenseRecord]
    @Query private var budgetCategories: [BudgetCategory]

    var onEditWedding: () -> Void
    var onQuickAction: (QuickAction) -> Void
    var onBackup: () -> Void

    private var profile: WeddingProfile? {
        profiles.first
    }

    private var weddingDate: Date {
        profile?.weddingDate ?? Date()
    }

    private var daysLeft: Int {
        DateHelper.daysUntilWedding(weddingDate: weddingDate)
    }

    // Task statistics
    private var completedTasks: Int {
        tasks.filter { $0.isCompleted }.count
    }
    private var pendingTasks: Int {
        tasks.filter { !$0.isCompleted && !$0.isOverdue(weddingDate: weddingDate) }.count
    }
    private var overdueTasks: Int {
        tasks.filter { $0.isOverdue(weddingDate: weddingDate) }.count
    }
    private var taskCompletionRate: Double {
        guard tasks.count > 0 else { return 0 }
        return Double(completedTasks) / Double(tasks.count)
    }

    // Budget statistics
    private var totalBudget: Double {
        profile?.totalBudget ?? 0
    }
    private var totalExpenses: Double {
        expenses.filter { $0.isPaid }.reduce(0) { $0 + $1.amount }
    }
    private var plannedExpenses: Double {
        expenses.filter { !$0.isPaid }.reduce(0) { $0 + $1.amount }
    }
    private var remainingBudget: Double {
        totalBudget - totalExpenses
    }
    private var budgetUsageRate: Double {
        guard totalBudget > 0 else { return 0 }
        return totalExpenses / totalBudget
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.sectionSpacing) {
                    countdownCard
                    quickActionsGrid
                    taskProgressCard
                    budgetOverviewCard
                    backupButton
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100) // FAB space
            }
            .background(AppTheme.bg)
            .navigationTitle("备婚总览")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        onBackup()
                    } label: {
                        Image(systemName: "arrow.uturn.square")
                            .foregroundColor(AppTheme.primaryColor)
                    }
                }
            }
        }
    }

    // MARK: - Countdown Card
    private var countdownCard: some View {
        ZStack(alignment: .topTrailing) {
            // Background gradient
            LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.accentColor],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
            .shadow(color: AppTheme.primaryColor.opacity(0.3), radius: 10, x: 0, y: 4)

            VStack(alignment: .center, spacing: 8) {
                Text("WEDDING COUNTDOWN")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .tracking(2)
                    .foregroundColor(.white.opacity(0.7))

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(max(daysLeft, 0))")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("天后")
                        .font(AppTheme.headline)
                        .foregroundColor(.white.opacity(0.9))
                }

                Text("我们结婚啦")
                    .font(AppTheme.title)
                    .foregroundColor(.white)

                Text(DateHelper.formatChineseDate(weddingDate))
                    .font(AppTheme.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)

            // Edit button
            Button {
                onEditWedding()
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Circle().fill(.white.opacity(0.2)))
            }
            .padding(12)
        }
    }

    // MARK: - Quick Actions Grid
    private var quickActionsGrid: some View {
        HStack(spacing: 12) {
            QuickActionItem(icon: "calendar.badge.plus", title: "新增任务", color: AppTheme.secondaryColor) {
                onQuickAction(.addTask)
            }
            QuickActionItem(icon: "creditcard.fill", title: "新增预算", color: AppTheme.successColor) {
                onQuickAction(.addExpense)
            }
            QuickActionItem(icon: "storefront.fill", title: "新增商家", color: AppTheme.infoColor) {
                onQuickAction(.addVendor)
            }
            QuickActionItem(icon: "list.clipboard.fill", title: "新增物资", color: AppTheme.warningColor) {
                onQuickAction(.addMaterial)
            }
        }
    }

    // MARK: - Task Progress Card
    private var taskProgressCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("筹备进度")
                    .font(AppTheme.headline)
                    .foregroundColor(AppTheme.primaryText)
                Spacer()
                HStack(spacing: 2) {
                    Text("时间规划")
                    Image(systemName: "chevron.right")
                }
                .font(AppTheme.smallCaption)
                .foregroundColor(AppTheme.secondaryText)
            }

            HStack(spacing: 20) {
                // Ring chart
                if tasks.count > 0 {
                    RingChartView(
                        segments: [
                            RingChartView.RingSegment(value: Double(completedTasks) / Double(tasks.count), color: AppTheme.successColor, label: "已完成"),
                            RingChartView.RingSegment(value: Double(pendingTasks) / Double(tasks.count), color: AppTheme.warningColor, label: "进行中"),
                            RingChartView.RingSegment(value: Double(overdueTasks) / Double(tasks.count), color: AppTheme.dangerColor, label: "已逾期")
                        ],
                        lineWidth: 14,
                        centerText: "\(Int(taskCompletionRate * 100))%",
                        centerSubtext: "完成率"
                    )
                    .frame(width: 100, height: 100)
                } else {
                    ProgressRingView(progress: 0, centerText: "0%")
                        .frame(width: 100, height: 100)
                }

                // Legend
                VStack(alignment: .leading, spacing: 8) {
                    LegendItem(color: AppTheme.successColor, text: "已完成", count: completedTasks)
                    LegendItem(color: AppTheme.warningColor, text: "进行中", count: pendingTasks)
                    LegendItem(color: AppTheme.dangerColor, text: "已逾期", count: overdueTasks)
                    LegendItem(color: Color.gray.opacity(0.5), text: "总任务", count: tasks.count)
                }
                Spacer()
            }
        }
        .cardStyle()
    }

    // MARK: - Budget Overview Card
    private var budgetOverviewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("预算使用")
                    .font(AppTheme.headline)
                    .foregroundColor(AppTheme.primaryText)
                Spacer()
                HStack(spacing: 2) {
                    Text("预算管理")
                    Image(systemName: "chevron.right")
                }
                .font(AppTheme.smallCaption)
                .foregroundColor(AppTheme.secondaryText)
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("已支出")
                        .font(AppTheme.smallCaption)
                        .foregroundColor(AppTheme.secondaryText)
                    Text(DateHelper.formatCurrency(totalExpenses))
                        .font(AppTheme.title)
                        .foregroundColor(AppTheme.accentColor)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("总预算")
                        .font(AppTheme.smallCaption)
                        .foregroundColor(AppTheme.secondaryText)
                    Text(DateHelper.formatCurrency(totalBudget))
                        .font(AppTheme.title)
                        .foregroundColor(AppTheme.primaryText)
                    Text("剩余 \(DateHelper.formatCurrency(remainingBudget))")
                        .font(AppTheme.smallCaption)
                        .foregroundColor(AppTheme.successColor)
                }
            }

            ProgressBarView(
                progress: budgetUsageRate,
                height: 8,
                color: AppTheme.primaryColor
            )

            if plannedExpenses > 0 {
                Text("含未付计划支出 \(DateHelper.formatCurrency(plannedExpenses))")
                    .font(AppTheme.smallCaption)
                    .foregroundColor(AppTheme.secondaryText)
            }
        }
        .cardStyle()
    }

    // MARK: - Backup Button
    private var backupButton: some View {
        Button {
            onBackup()
        } label: {
            Label("数据备份", systemImage: "icloud.and.arrow.up.fill")
                .font(AppTheme.caption)
                .foregroundColor(AppTheme.secondaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Quick Action Item
private struct QuickActionItem: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(color))

                Text(title)
                    .font(AppTheme.smallCaption)
                    .foregroundColor(AppTheme.primaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius, style: .continuous)
                    .fill(AppTheme.cardBg)
                    .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Legend Item
private struct LegendItem: View {
    let color: Color
    let text: String
    let count: Int

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(text)
                .font(AppTheme.smallCaption)
                .foregroundColor(AppTheme.secondaryText)
            Text("\(count)项")
                .font(AppTheme.smallCaption)
                .foregroundColor(AppTheme.primaryText)
                .fontWeight(.medium)
        }
    }
}
