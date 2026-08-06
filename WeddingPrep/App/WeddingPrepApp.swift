import SwiftUI
import SwiftData

@main
struct WeddingPrepApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            WeddingProfile.self,
            TaskItem.self,
            BudgetCategory.self,
            ExpenseRecord.self,
            Vendor.self,
            MaterialItem.self
        ])
    }
}
