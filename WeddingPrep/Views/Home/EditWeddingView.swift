import SwiftUI
import SwiftData

struct EditWeddingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [WeddingProfile]
    @Query private var tasks: [TaskItem]

    @State private var weddingDate: Date = Date()
    @State private var brideName: String = ""
    @State private var groomName: String = ""
    @State private var totalBudget: Double = 100000
    @State private var budgetText: String = "100000"

    private var profile: WeddingProfile? {
        profiles.first
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("婚礼信息") {
                    DatePicker("婚礼日期", selection: $weddingDate, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "zh_CN"))

                    HStack {
                        Text("新郎姓名")
                        Spacer()
                        TextField("请输入", text: $groomName)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("新娘姓名")
                        Spacer()
                        TextField("请输入", text: $brideName)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section("预算设置") {
                    HStack {
                        Text("总预算")
                        Spacer()
                        TextField("金额", text: $budgetText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: budgetText) { _, newValue in
                                let filtered = newValue.filter { $0.isNumber }
                                budgetText = filtered
                                totalBudget = Double(filtered) ?? 0
                            }
                        Text("元")
                            .foregroundColor(AppTheme.secondaryText)
                    }

                    if profile != nil {
                        Text("距婚礼还有 \(DateHelper.daysUntilWedding(weddingDate: weddingDate)) 天")
                            .font(AppTheme.caption)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                }

                Section {
                    Button("保存") {
                        saveProfile()
                    }
                    .font(AppTheme.headline)
                    .foregroundColor(AppTheme.primaryColor)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("编辑婚礼信息")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .onAppear {
                loadProfile()
            }
        }
    }

    private func loadProfile() {
        if let profile {
            weddingDate = profile.weddingDate
            brideName = profile.brideName
            groomName = profile.groomName
            totalBudget = profile.totalBudget
            budgetText = String(Int(profile.totalBudget))
        }
    }

    private func saveProfile() {
        if let profile {
            profile.weddingDate = weddingDate
            profile.brideName = brideName
            profile.groomName = groomName
            profile.totalBudget = totalBudget
            profile.updatedAt = Date()
        } else {
            let newProfile = WeddingProfile(
                weddingDate: weddingDate,
                brideName: brideName,
                groomName: groomName,
                totalBudget: totalBudget
            )
            modelContext.insert(newProfile)
        }
        try? modelContext.save()

        // 婚礼日期修改后重新安排所有通知
        NotificationManager.scheduleAllTaskNotifications(tasks: tasks, weddingDate: weddingDate)
        NotificationManager.scheduleWeddingCountdown(weddingDate: weddingDate)

        dismiss()
    }
}
