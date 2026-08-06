import SwiftUI
import SwiftData

struct EditBudgetCategoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var budgetCategories: [BudgetCategory]

    @State private var newCategoryName = ""
    @State private var editingCategory: BudgetCategory?
    @State private var editLimitText = ""
    @State private var editLimit: Double = 0

    private var sortedCategories: [BudgetCategory] {
        budgetCategories.sorted { $0.order < $1.order }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("预算分类") {
                    ForEach(sortedCategories, id: \.id) { category in
                        HStack {
                            Circle()
                                .fill(Color(hex: category.colorHex))
                                .frame(width: 12, height: 12)
                            Text(category.name)
                                .font(AppTheme.body)
                            Spacer()
                            Text(DateHelper.formatCurrency(category.budgetLimit))
                                .font(AppTheme.caption)
                                .foregroundColor(AppTheme.secondaryText)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            editingCategory = category
                            editLimit = category.budgetLimit
                            editLimitText = String(format: "%.0f", category.budgetLimit)
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                deleteCategory(category)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                    }
                }

                Section("新增分类") {
                    HStack {
                        TextField("分类名称", text: $newCategoryName)
                        Button {
                            addCategory()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(newCategoryName.isEmpty ? .gray : AppTheme.primaryColor)
                        }
                        .disabled(newCategoryName.isEmpty)
                    }
                }
            }
            .navigationTitle("设置分类预算")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") { dismiss() }
                }
            }
            .sheet(item: $editingCategory) { category in
                editLimitSheet(category)
            }
        }
    }

    private func addCategory() {
        guard !newCategoryName.isEmpty else { return }
        let maxOrder = budgetCategories.map { $0.order }.max() ?? -1
        let newCategory = BudgetCategory(
            name: newCategoryName,
            budgetLimit: 0,
            colorHex: "#D5DBDB",
            order: maxOrder + 1
        )
        modelContext.insert(newCategory)
        try? modelContext.save()
        newCategoryName = ""
    }

    private func deleteCategory(_ category: BudgetCategory) {
        modelContext.delete(category)
        try? modelContext.save()
    }

    private func editLimitSheet(_ category: BudgetCategory) -> some View {
        NavigationStack {
            Form {
                Section("设置 \(category.name) 预算上限") {
                    HStack {
                        TextField("金额", text: $editLimitText)
                            .keyboardType(.numberPad)
                            .onChange(of: editLimitText) { _, newValue in
                                let filtered = newValue.filter { $0.isNumber }
                                editLimitText = filtered
                                editLimit = Double(filtered) ?? 0
                            }
                        Text("元")
                            .foregroundColor(AppTheme.secondaryText)
                    }
                }
                Section {
                    Button("保存") {
                        category.budgetLimit = editLimit
                        try? modelContext.save()
                        editingCategory = nil
                    }
                    .font(AppTheme.headline)
                    .foregroundColor(AppTheme.primaryColor)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("分类预算")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { editingCategory = nil }
                }
            }
        }
    }
}
