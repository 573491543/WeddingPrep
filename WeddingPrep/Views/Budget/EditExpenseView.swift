import SwiftUI
import SwiftData

struct EditExpenseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var budgetCategories: [BudgetCategory]
    @Query private var vendors: [Vendor]

    var expense: ExpenseRecord?

    @State private var amountText = ""
    @State private var amount: Double = 0
    @State private var categoryName = ""
    @State private var date = Date()
    @State private var isPaid = false
    @State private var note = ""
    @State private var vendorName = ""

    private var isEditing: Bool { expense != nil }

    private var sortedCategories: [BudgetCategory] {
        budgetCategories.sorted { $0.order < $1.order }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("支出信息") {
                    HStack {
                        Text("金额")
                        Spacer()
                        TextField("0", text: $amountText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: amountText) { _, newValue in
                                let filtered = newValue.filter { $0.isNumber || $0 == "." }
                                amountText = filtered
                                amount = Double(filtered) ?? 0
                            }
                        Text("元")
                            .foregroundColor(AppTheme.secondaryText)
                    }

                    Picker("分类", selection: $categoryName) {
                        ForEach(sortedCategories, id: \.id) { cat in
                            Text(cat.name).tag(cat.name)
                        }
                    }

                    DatePicker("日期", selection: $date, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "zh_CN"))
                }

                Section("支付状态") {
                    Toggle("已支付", isOn: $isPaid)
                }

                Section("关联商家（可选）") {
                    Picker("商家", selection: $vendorName) {
                        Text("无").tag("")
                        ForEach(vendors, id: \.id) { vendor in
                            Text(vendor.name).tag(vendor.name)
                        }
                    }
                }

                Section("备注") {
                    TextField("备注...", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section {
                    Button(isEditing ? "保存修改" : "添加记录") {
                        saveExpense()
                    }
                    .font(AppTheme.headline)
                    .foregroundColor(AppTheme.primaryColor)
                    .frame(maxWidth: .infinity)
                    .disabled(amount <= 0 || categoryName.isEmpty)

                    if isEditing {
                        Button("删除记录", role: .destructive) {
                            deleteExpense()
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle(isEditing ? "编辑支出" : "新增支出")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .onAppear {
                loadExpense()
                if categoryName.isEmpty, let first = sortedCategories.first {
                    categoryName = first.name
                }
            }
        }
    }

    private func loadExpense() {
        guard let expense else { return }
        amount = expense.amount
        amountText = String(format: "%.0f", expense.amount)
        categoryName = expense.categoryName
        date = expense.date
        isPaid = expense.isPaid
        note = expense.note
        vendorName = expense.vendorName ?? ""
    }

    private func saveExpense() {
        if let expense {
            expense.amount = amount
            expense.categoryName = categoryName
            expense.date = date
            expense.isPaid = isPaid
            expense.note = note
            expense.vendorName = vendorName.isEmpty ? nil : vendorName
            expense.updatedAt = Date()
        } else {
            let newExpense = ExpenseRecord(
                amount: amount,
                categoryName: categoryName,
                date: date,
                isPaid: isPaid,
                note: note,
                vendorName: vendorName.isEmpty ? nil : vendorName
            )
            modelContext.insert(newExpense)
        }
        try? modelContext.save()
        dismiss()
    }

    private func deleteExpense() {
        guard let expense else { return }
        modelContext.delete(expense)
        try? modelContext.save()
        dismiss()
    }
}
