import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - Notification Names
extension Notification.Name {
    static let addTask = Notification.Name("AddTaskTrigger")
    static let addExpense = Notification.Name("AddExpenseTrigger")
    static let addVendor = Notification.Name("AddVendorTrigger")
    static let addMaterial = Notification.Name("AddMaterialTrigger")
}

enum QuickAction {
    case addTask, addExpense, addVendor, addMaterial
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: AppTab = .home
    @State private var showEditWedding = false
    @State private var showBackupSheet = false

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(
                onEditWedding: { showEditWedding = true },
                onQuickAction: { action in handleQuickAction(action) },
                onBackup: { showBackupSheet = true }
            )
            .tabItem {
                Label(AppTab.home.title, systemImage: AppTab.home.icon)
            }
            .tag(AppTab.home)

            TimePlanView()
            .tabItem {
                Label(AppTab.timePlan.title, systemImage: AppTab.timePlan.icon)
            }
            .tag(AppTab.timePlan)

            BudgetView()
            .tabItem {
                Label(AppTab.budget.title, systemImage: AppTab.budget.icon)
            }
            .tag(AppTab.budget)

            VendorView()
            .tabItem {
                Label(AppTab.vendor.title, systemImage: AppTab.vendor.icon)
            }
            .tag(AppTab.vendor)

            MaterialView()
            .tabItem {
                Label(AppTab.material.title, systemImage: AppTab.material.icon)
            }
            .tag(AppTab.material)

            ReminderView()
            .tabItem {
                Label(AppTab.reminder.title, systemImage: AppTab.reminder.icon)
            }
            .tag(AppTab.reminder)
        }
        .tint(AppTheme.primaryColor)
        .onAppear {
            checkFirstLaunch()
        }
        .sheet(isPresented: $showEditWedding) {
            EditWeddingView()
        }
        .sheet(isPresented: $showBackupSheet) {
            BackupSheetView()
        }
    }

    private func handleQuickAction(_ action: QuickAction) {
        switch action {
        case .addTask:
            selectedTab = .timePlan
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                NotificationCenter.default.post(name: .addTask, object: nil)
            }
        case .addExpense:
            selectedTab = .budget
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                NotificationCenter.default.post(name: .addExpense, object: nil)
            }
        case .addVendor:
            selectedTab = .vendor
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                NotificationCenter.default.post(name: .addVendor, object: nil)
            }
        case .addMaterial:
            selectedTab = .material
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                NotificationCenter.default.post(name: .addMaterial, object: nil)
            }
        }
    }

    // MARK: - First Launch Check
    private func checkFirstLaunch() {
        var profiles = (try? modelContext.fetch(FetchDescriptor<WeddingProfile>())) ?? []
        if profiles.isEmpty {
            // 首次启动，创建默认婚礼档案并预填数据
            SeedDataManager.seedInitialData(context: modelContext)
            // 重新获取已预填的档案
            profiles = (try? modelContext.fetch(FetchDescriptor<WeddingProfile>())) ?? []
        }

        // 请求本地通知权限
        NotificationManager.requestPermission()

        // 安排所有任务通知
        let tasks = (try? modelContext.fetch(FetchDescriptor<TaskItem>())) ?? []
        if let weddingDate = profiles.first?.weddingDate {
            NotificationManager.scheduleAllTaskNotifications(tasks: tasks, weddingDate: weddingDate)
            NotificationManager.scheduleWeddingCountdown(weddingDate: weddingDate)
        }
    }
}

// MARK: - Backup Sheet View
struct BackupSheetView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showImport = false
    @State private var exportURL: URL?
    @State private var showShareSheet = false
    @State private var importError = ""
    @State private var showError = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "externaldrive.fill.badge.plus")
                    .font(.system(size: 56))
                    .foregroundColor(AppTheme.primaryColor)
                    .padding(.top, 40)

                Text("数据备份")
                    .font(AppTheme.title)

                Text("所有数据仅保存在本机，建议定期导出备份以防数据丢失")
                    .font(AppTheme.caption)
                    .foregroundColor(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                VStack(spacing: 16) {
                    Button {
                        exportData()
                    } label: {
                        Label("导出备份文件", systemImage: "square.and.arrow.up.fill")
                            .font(AppTheme.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius)
                                    .fill(AppTheme.primaryColor)
                            )
                    }
                    .buttonStyle(ScaleButtonStyle())

                    Button {
                        showImport = true
                    } label: {
                        Label("导入备份文件", systemImage: "square.and.arrow.down.fill")
                            .font(AppTheme.headline)
                            .foregroundColor(AppTheme.primaryColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius)
                                    .stroke(AppTheme.primaryColor, lineWidth: 1.5)
                            )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .padding(.horizontal, 24)

                Spacer()
            }
            .navigationTitle("数据备份")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let exportURL {
                    ShareSheet(items: [exportURL])
                }
            }
            .fileImporter(
                isPresented: $showImport,
                allowedContentTypes: [.json]
            ) { result in
                handleImport(result)
            }
            .alert("导入失败", isPresented: $showError) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(importError)
            }
        }
    }

    private func exportData() {
        do {
            let url = try DataBackupManager.exportData(context: modelContext)
            exportURL = url
            showShareSheet = true
        } catch {
            importError = "导出失败：\(error.localizedDescription)"
            showError = true
        }
    }

    private func handleImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            do {
                try DataBackupManager.importData(from: url, context: modelContext)
                dismiss()
            } catch {
                importError = "导入失败：\(error.localizedDescription)"
                showError = true
            }
        case .failure(let error):
            importError = "文件读取失败：\(error.localizedDescription)"
            showError = true
        }
    }
}

// MARK: - Share Sheet (UIViewControllerRepresentable)
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
