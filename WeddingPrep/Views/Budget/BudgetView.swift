import SwiftUI
import SwiftData

struct BudgetView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [WeddingProfile]
    @Query private var expenses: [ExpenseRecord]
    @Query private var budgetCategories: [BudgetCategory]

    @State private var showAddSheet = false
    @State private var editingExpense: ExpenseRecord?
    @State private var showCategoryEditor = false

    private var profile: WeddingProfile? { profiles.first }
    private var totalBudget: Double { profile?.totalBudget ?? 0 }
    private var totalPaid: Double { expenses.filter { $0.isPaid }.reduce(0) { $0 + $1.amount } }
    private var totalUnpaid: Double { expenses.filter { !$0.isPaid }.reduce(0) { $0 + $1.amount } }
    private var totalPlanned: Double { totalPaid + totalUnpaid }
    private var remaining: Double { totalBudget - totalPaid }
    private var budgetUsageRate: Double {
        guard totalBudget > 0 else { return 0 }
        return totalPaid / totalBudget
    }

    private var sortedCategories: [BudgetCategory] {
        budgetCategories.sorted { $0.order < $1.order }
    }

    // Category spending
    private func spentFor(category: String) -> Double {
        expenses.filter { $0.categoryName == category && $0.isPaid }.reduce(0) { $0 + $1.amount }
    }
    private func unpaidFor(category: String) -> Double {
        expenses.filter { $0.categoryName == category && !$0.isPaid }.reduce(0) { $0 + $1.amount }
    }

    // Category breakdown for ring chart
    private var categoryBreakdown: [(category: BudgetCategory, amount: Double, percent: Double)] {
        let totalSpent = sortedCategories.reduce(0.0) { $0 + spentFor(category: $1.name) }
        return sortedCategories.map { cat in
            let amt = spentFor(category: cat.name)
            let pct = totalSpent > 0 ? amt / totalSpent : 0
            return (cat, amt, pct)
        }.filter { $0.amount > 0 }
    }

    private var totalPaidCount: Int { expenses.filter { $0.isPaid }.count }
    private var totalUnpaidCount: Int { expenses.filter { !$0.isPaid }.count }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.sectionSpacing) {
                    budgetOverviewCard
                    categoryBreakdownCard
                    categoryLedgerSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
            }
            .background(AppTheme.bg)
            .navigationTitle("预算管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCategoryEditor = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(AppTheme.primaryColor)
                    }
                }
            }
            .overlay(alignment: .bottomTrailing) {
                FloatingActionButton {
                    showAddSheet = true
                }
                .padding(.trailing, 20)
                .padding(.bottom, 40)
            }
            .sheet(isPresented: $showAddSheet) {
                EditExpenseView()
            }
            .sheet(item: $editingExpense) { expense in
                EditExpenseView(expense: expense)
            }
            .sheet(isPresented: $showCategoryEditor) {
                EditBudgetCategoryView()
            }
            .onReceive(NotificationCenter.default.publisher(for: .addExpense)) { _ in
                showAddSheet = true
            }
        }
    }

    // MARK: - Budget Overview Card
    private var budgetOverviewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("总预算")
                    .font(AppTheme.smallCaption)
                    .foregroundColor(AppTheme.secondaryText)
                Text(DateHelper.formatCurrency(totalBudget))
                    .font(AppTheme.bigNumber)
                    .foregroundColor(AppTheme.primaryText)
            }

            // Progress bar with marker
            ProgressBarView(
                progress: budgetUsageRate,
                height: 10,
                color: AppTheme.primaryColor,
                showMarker: true
            )

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("已支出")
                        .font(AppTheme.smallCaption)
                        .foregroundColor(AppTheme.secondaryText)
                    Text(DateHelper.formatCurrency(totalPaid))
                        .font(AppTheme.title)
                        .foregroundColor(AppTheme.accentColor)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("剩余可用")
                        .font(AppTheme.smallCaption)
                        .foregroundColor(AppTheme.secondaryText)
                    Text(DateHelper.formatCurrency(remaining))
                        .font(AppTheme.title)
                        .foregroundColor(AppTheme.successColor)
                }
            }

            if totalUnpaid > 0 {
                Text("含未付计划支出 \(DateHelper.formatCurrency(totalUnpaid))（缺口 \(DateHelper.formatCurrency(max(totalBudget - totalPlanned, 0)))）")
                    .font(AppTheme.smallCaption)
                    .foregroundColor(AppTheme.secondaryText)
            }

            Text("共 \(expenses.count) 笔记录 · 已支付 \(totalPaidCount) 笔 · 未付 \(totalUnpaidCount) 笔")
                .font(AppTheme.smallCaption)
                .foregroundColor(AppTheme.secondaryText)
        }
        .cardStyle()
    }

    // MARK: - Category Breakdown Card
    private var categoryBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("分类花销占比")
                .font(AppTheme.headline)
                .foregroundColor(AppTheme.primaryText)

            if categoryBreakdown.isEmpty {
                EmptyStateView(icon: "chart.pie.fill", title: "暂无支出记录", subtitle: "添加支出后这里将显示占比")
                    .padding(.vertical, 20)
            } else {
                HStack(spacing: 20) {
                    // Ring chart
                    RingChartView(
                        segments: categoryBreakdown.map { item in
                            RingChartView.RingSegment(
                                value: item.percent,
                                color: Color(hex: item.category.colorHex),
                                label: item.category.name
                            )
                        },
                        lineWidth: 14,
                        centerText: DateHelper.formatCurrency(totalPaid),
                        centerSubtext: "已支出"
                    )
                    .frame(width: 110, height: 110)

                    // Legend
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(categoryBreakdown, id: \.category.id) { item in
                            HStack(spacing: 6) {
                                Rectangle()
                                    .fill(Color(hex: item.category.colorHex))
                                    .frame(width: 10, height: 10)
                                    .clipShape(RoundedRectangle(cornerRadius: 2))
                                Text(item.category.name)
                                    .font(AppTheme.smallCaption)
                                    .foregroundColor(AppTheme.secondaryText)
                                Spacer()
                                Text(DateHelper.formatCurrency(item.amount))
                                    .font(AppTheme.smallCaption)
                                    .foregroundColor(AppTheme.primaryText)
                                Text("·\(Int(item.percent * 100))%")
                                    .font(AppTheme.smallCaption)
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                        }
                    }
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Category Ledger Section
    private var categoryLedgerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("分类预算台账")
                    .font(AppTheme.headline)
                    .foregroundColor(AppTheme.primaryText)
                Spacer()
                Button {
                    showCategoryEditor = true
                } label: {
                    HStack(spacing: 2) {
                        Text("设置分类预算")
                        Image(systemName: "chevron.right")
                    }
                    .font(AppTheme.smallCaption)
                    .foregroundColor(AppTheme.secondaryText)
                }
            }

            ForEach(sortedCategories, id: \.id) { category in
                categoryLedgerRow(category)
            }
        }
        .cardStyle()
    }

    private func categoryLedgerRow(_ category: BudgetCategory) -> some View {
        let spent = spentFor(category: category.name)
        let unpaid = unpaidFor(category: category.name)
        let limit = category.budgetLimit
        let progress = limit > 0 ? spent / limit : 0
        let isOverBudget = limit > 0 && spent > limit

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(category.name)
                    .font(AppTheme.headline)
                    .foregroundColor(AppTheme.primaryText)
                Spacer()
                Text("\(DateHelper.formatCurrency(spent)) / \(DateHelper.formatCurrency(limit))")
                    .font(AppTheme.caption)
                    .foregroundColor(AppTheme.secondaryText)
            }

            if limit > 0 {
                ProgressBarView(
                    progress: progress,
                    height: 6,
                    color: isOverBudget ? AppTheme.dangerColor : AppTheme.successColor
                )
            }

            HStack(spacing: 12) {
                Text("已付 \(DateHelper.formatCurrency(spent))")
                    .font(AppTheme.smallCaption)
                    .foregroundColor(AppTheme.secondaryText)
                if unpaid > 0 {
                    Text("未付 \(DateHelper.formatCurrency(unpaid))")
                        .font(AppTheme.smallCaption)
                        .foregroundColor(AppTheme.warningColor)
                }
                Spacer()
                if limit > 0 {
                    Text("剩余 \(DateHelper.formatCurrency(max(limit - spent, 0)))")
                        .font(AppTheme.smallCaption)
                        .foregroundColor(isOverBudget ? AppTheme.dangerColor : AppTheme.successColor)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius)
                .fill(AppTheme.bg.opacity(0.5))
        )
    }
}
