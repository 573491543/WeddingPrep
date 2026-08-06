import Foundation
import SwiftData

// MARK: - SeedDataManager (首次启动预填数据)
enum SeedDataManager {

    /// 首次启动时初始化默认数据
    static func seedInitialData(context: ModelContext) {
        // Check if already seeded
        let existingProfiles = (try? context.fetch(FetchDescriptor<WeddingProfile>())) ?? []
        guard existingProfiles.isEmpty else { return }

        // 1. Create default wedding profile
        let defaultDate = Calendar.current.date(byAdding: .month, value: 9, to: Date()) ?? Date()
        let profile = WeddingProfile(
            weddingDate: defaultDate,
            brideName: "",
            groomName: "",
            totalBudget: 100000
        )
        context.insert(profile)

        // 2. Seed budget categories
        seedBudgetCategories(context: context)

        // 3. Seed task templates
        seedTaskTemplates(context: context)

        try? context.save()
    }

    // MARK: - Budget Categories
    private static func seedBudgetCategories(context: ModelContext) {
        for (index, preset) in BudgetCategoryPreset.allCases.enumerated() {
            let category = BudgetCategory(
                name: preset.rawValue,
                budgetLimit: preset.defaultLimit,
                colorHex: preset.colorHex,
                order: index
            )
            context.insert(category)
        }
    }

    // MARK: - Task Templates (约30条常见备婚任务)
    private static func seedTaskTemplates(context: ModelContext) {
        let templates: [(title: String, stage: TaskStage, category: TaskCategory, daysBefore: Int, priority: Priority, notes: String, reminder: Int)] = [
            // 婚前6个月
            ("双方家长见面商定婚期", .sixMonthsBefore, .family, 180, .high, "确定大致婚礼日期范围", 7),
            ("确定婚礼预算总金额", .sixMonthsBefore, .other, 180, .high, "与双方家庭商议预算分配", 7),
            ("挑选并预定婚宴酒店", .sixMonthsBefore, .banquet, 175, .high, "热门档期需提前半年预定", 7),
            ("开始考察婚纱摄影机构", .sixMonthsBefore, .photography, 170, .medium, "对比3家以上，看客片和样片", 5),
            ("预定婚庆策划公司", .sixMonthsBefore, .decoration, 165, .medium, "", 5),

            // 婚前3个月
            ("拍摄婚纱照", .threeMonthsBefore, .photography, 90, .high, "提前预约外景场地", 7),
            ("挑选婚纱礼服", .threeMonthsBefore, .dress, 85, .high, "出门纱、主婚纱、敬酒服", 5),
            ("确定跟妆师并试妆", .threeMonthsBefore, .beauty, 80, .high, "带参考图沟通风格", 5),
            ("预定婚车", .threeMonthsBefore, .other, 75, .low, "", 3),
            ("确定伴郎伴娘人选", .threeMonthsBefore, .family, 70, .medium, "", 5),
            ("制作宾客名单", .threeMonthsBefore, .family, 65, .medium, "双方各自统计人数", 3),
            ("选购婚戒首饰", .threeMonthsBefore, .other, 60, .high, "预留定制时间", 7),

            // 婚前1个月
            ("发送请柬", .oneMonthBefore, .family, 30, .high, "电子请柬+纸质请柬", 7),
            ("确定最终宾客人数", .oneMonthBefore, .family, 25, .high, "通知酒店调整桌数", 3),
            ("与婚庆确认最终方案", .oneMonthBefore, .decoration, 25, .high, "场地布置、流程确认", 3),
            ("试穿最终婚纱礼服", .oneMonthBefore, .dress, 20, .high, "确认尺寸是否需要调整", 3),
            ("确定婚礼当天流程表", .oneMonthBefore, .other, 20, .high, "", 3),
            ("采购婚房布置用品", .oneMonthBefore, .decoration, 18, .medium, "喜字贴纸、气球、床品", 3),
            ("采购喜糖喜品", .oneMonthBefore, .other, 15, .medium, "确定数量和款式", 3),
            ("与司仪沟通婚礼流程", .oneMonthBefore, .other, 15, .medium, "", 3),
            ("安排伴郎伴娘服装", .oneMonthBefore, .dress, 12, .low, "", 3),

            // 婚前1周
            ("最终试纱确认", .oneWeekBefore, .dress, 7, .high, "", 2),
            ("确认所有商家到场时间", .oneWeekBefore, .other, 5, .high, "化妆师、摄影、婚庆", 1),
            ("准备婚礼当天随身物品", .oneWeekBefore, .other, 5, .high, "敬酒服、备用丝袜、针线包", 1),
            ("打印座位图和流程表", .oneWeekBefore, .other, 3, .medium, "", 1),
            ("婚房最后布置", .oneWeekBefore, .decoration, 2, .medium, "", 1),

            // 婚礼当天
            ("早起化妆造型", .weddingDay, .beauty, 0, .high, "比约定时间提前30分钟", 0),
            ("迎宾接待", .weddingDay, .family, 0, .high, "", 0),
            ("婚礼仪式", .weddingDay, .other, 0, .high, "", 0),
            ("婚宴敬酒", .weddingDay, .banquet, 0, .high, "", 0),
            ("送客收拾", .weddingDay, .other, 0, .low, "", 0),
        ]

        for template in templates {
            let task = TaskItem(
                title: template.title,
                stage: template.stage.rawValue,
                category: template.category.rawValue,
                type: TaskType.task.rawValue,
                daysBeforeWedding: template.daysBefore,
                priority: template.priority.rawValue,
                isCompleted: false,
                notes: template.notes,
                reminderDaysBefore: template.reminder
            )
            context.insert(task)
        }
    }

    // MARK: - Reset All Data (危险操作)
    static func resetAllData(context: ModelContext) {
        // Delete all records
        let profiles = (try? context.fetch(FetchDescriptor<WeddingProfile>())) ?? []
        let tasks = (try? context.fetch(FetchDescriptor<TaskItem>())) ?? []
        let categories = (try? context.fetch(FetchDescriptor<BudgetCategory>())) ?? []
        let expenses = (try? context.fetch(FetchDescriptor<ExpenseRecord>())) ?? []
        let vendors = (try? context.fetch(FetchDescriptor<Vendor>())) ?? []
        let materials = (try? context.fetch(FetchDescriptor<MaterialItem>())) ?? []

        for item in profiles { context.delete(item) }
        for item in tasks { context.delete(item) }
        for item in categories { context.delete(item) }
        for item in expenses { context.delete(item) }
        for item in vendors { context.delete(item) }
        for item in materials { context.delete(item) }

        try? context.save()
    }
}
