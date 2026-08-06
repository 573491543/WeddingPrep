import Foundation
import SwiftData
import SwiftUI

// MARK: - DataBackupManager (数据导出/导入)
enum DataBackupManager {

    // MARK: - Export

    /// 导出所有数据为 JSON 文件
    @discardableResult
    static func exportData(context: ModelContext) throws -> URL {
        // Fetch all data
        let profiles = try context.fetch(FetchDescriptor<WeddingProfile>())
        let tasks = try context.fetch(FetchDescriptor<TaskItem>())
        let categories = try context.fetch(FetchDescriptor<BudgetCategory>())
        let expenses = try context.fetch(FetchDescriptor<ExpenseRecord>())
        let vendors = try context.fetch(FetchDescriptor<Vendor>())
        let materials = try context.fetch(FetchDescriptor<MaterialItem>())

        // Build JSON dictionary
        let backup: [String: Any] = [
            "version": 1,
            "exportDate": ISO8601DateFormatter().string(from: Date()),
            "weddingProfiles": profiles.map { $0.toDictionary() },
            "taskItems": tasks.map { $0.toDictionary() },
            "budgetCategories": categories.map { $0.toDictionary() },
            "expenseRecords": expenses.map { $0.toDictionary() },
            "vendors": vendors.map { $0.toDictionary() },
            "materialItems": materials.map { $0.toDictionary() }
        ]

        // Convert to JSON Data
        let json = try JSONSerialization.data(withJSONObject: backup, options: [.prettyPrinted, .sortedKeys])

        // Write to temp file
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let fileName = "WeddingPrep_Backup_\(dateFormatter.string(from: Date())).wpbackup"
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)
        try json.write(to: fileURL)

        return fileURL
    }

    // MARK: - Import

    /// 从 JSON 文件导入数据
    static func importData(from url: URL, context: ModelContext) throws {
        // Access security scope
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing { url.stopAccessingSecurityScopedResource() }
        }

        // Read file
        let data = try Data(contentsOf: url)
        let backup = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        guard let backup else {
            throw BackupError.invalidFormat
        }

        // Fetch existing IDs for deduplication
        let existingTasks = try context.fetch(FetchDescriptor<TaskItem>())
        let existingCategories = try context.fetch(FetchDescriptor<BudgetCategory>())
        let existingExpenses = try context.fetch(FetchDescriptor<ExpenseRecord>())
        let existingVendors = try context.fetch(FetchDescriptor<Vendor>())
        let existingMaterials = try context.fetch(FetchDescriptor<MaterialItem>())
        let existingProfiles = try context.fetch(FetchDescriptor<WeddingProfile>())

        let existingTaskIds = Set(existingTasks.map { $0.id })
        let existingCategoryIds = Set(existingCategories.map { $0.id })
        let existingExpenseIds = Set(existingExpenses.map { $0.id })
        let existingVendorIds = Set(existingVendors.map { $0.id })
        let existingMaterialIds = Set(existingMaterials.map { $0.id })
        let existingProfileIds = Set(existingProfiles.map { $0.id })

        // Import WeddingProfile
        if let profiles = backup["weddingProfiles"] as? [[String: Any]] {
            for dict in profiles {
                guard let idStr = dict["id"] as? String,
                      let id = UUID(uuidString: idStr) else { continue }
                if existingProfileIds.contains(id) { continue }

                let profile = WeddingProfile(
                    weddingDate: parseDate(dict["weddingDate"] as? String) ?? Date(),
                    brideName: dict["brideName"] as? String ?? "",
                    groomName: dict["groomName"] as? String ?? "",
                    totalBudget: dict["totalBudget"] as? Double ?? 0
                )
                profile.id = id
                context.insert(profile)
            }
        }

        // Import BudgetCategories
        if let categories = backup["budgetCategories"] as? [[String: Any]] {
            for dict in categories {
                guard let idStr = dict["id"] as? String,
                      let id = UUID(uuidString: idStr) else { continue }
                if existingCategoryIds.contains(id) { continue }

                let cat = BudgetCategory(
                    name: dict["name"] as? String ?? "",
                    budgetLimit: dict["budgetLimit"] as? Double ?? 0,
                    colorHex: dict["colorHex"] as? String ?? "#E8A0BF",
                    order: dict["order"] as? Int ?? 0
                )
                cat.id = id
                context.insert(cat)
            }
        }

        // Import TaskItems
        if let tasks = backup["taskItems"] as? [[String: Any]] {
            for dict in tasks {
                guard let idStr = dict["id"] as? String,
                      let id = UUID(uuidString: idStr) else { continue }
                if existingTaskIds.contains(id) { continue }

                let task = TaskItem(
                    title: dict["title"] as? String ?? "",
                    stage: dict["stage"] as? String ?? TaskStage.oneMonthBefore.rawValue,
                    category: dict["category"] as? String ?? TaskCategory.other.rawValue,
                    type: dict["type"] as? String ?? TaskType.task.rawValue,
                    daysBeforeWedding: dict["daysBeforeWedding"] as? Int ?? 30,
                    priority: dict["priority"] as? Int ?? Priority.medium.rawValue,
                    isCompleted: dict["isCompleted"] as? Bool ?? false,
                    notes: dict["notes"] as? String ?? "",
                    reminderDaysBefore: dict["reminderDaysBefore"] as? Int ?? 3
                )
                task.id = id
                if let completedDateStr = dict["completedDate"] as? String {
                    task.completedDate = parseDate(completedDateStr)
                }
                context.insert(task)
            }
        }

        // Import ExpenseRecords
        if let expenses = backup["expenseRecords"] as? [[String: Any]] {
            for dict in expenses {
                guard let idStr = dict["id"] as? String,
                      let id = UUID(uuidString: idStr) else { continue }
                if existingExpenseIds.contains(id) { continue }

                let expense = ExpenseRecord(
                    amount: dict["amount"] as? Double ?? 0,
                    categoryName: dict["categoryName"] as? String ?? "",
                    date: parseDate(dict["date"] as? String) ?? Date(),
                    isPaid: dict["isPaid"] as? Bool ?? false,
                    note: dict["note"] as? String ?? "",
                    vendorName: dict["vendorName"] as? String
                )
                expense.id = id
                context.insert(expense)
            }
        }

        // Import Vendors
        if let vendors = backup["vendors"] as? [[String: Any]] {
            for dict in vendors {
                guard let idStr = dict["id"] as? String,
                      let id = UUID(uuidString: idStr) else { continue }
                if existingVendorIds.contains(id) { continue }

                let vendor = Vendor(
                    name: dict["name"] as? String ?? "",
                    serviceType: dict["serviceType"] as? String ?? VendorServiceType.other.rawValue,
                    price: dict["price"] as? Double ?? 0,
                    status: dict["status"] as? String ?? VendorStatus.intentional.rawValue,
                    contactDate: parseDate(dict["contactDate"] as? String),
                    phone: dict["phone"] as? String ?? "",
                    notes: dict["notes"] as? String ?? ""
                )
                vendor.id = id
                context.insert(vendor)
            }
        }

        // Import MaterialItems
        if let materials = backup["materialItems"] as? [[String: Any]] {
            for dict in materials {
                guard let idStr = dict["id"] as? String,
                      let id = UUID(uuidString: idStr) else { continue }
                if existingMaterialIds.contains(id) { continue }

                let material = MaterialItem(
                    name: dict["name"] as? String ?? "",
                    price: dict["price"] as? Double ?? 0,
                    quantity: dict["quantity"] as? Int ?? 1,
                    category: dict["category"] as? String ?? MaterialCategory.other.rawValue,
                    channel: dict["channel"] as? String ?? MaterialChannel.taobao.rawValue,
                    status: dict["status"] as? String ?? MaterialStatus.notPurchased.rawValue,
                    notes: dict["notes"] as? String ?? "",
                    listType: dict["listType"] as? String ?? MaterialListType.purchase.rawValue
                )
                material.id = id
                context.insert(material)
            }
        }

        try context.save()
    }

    // MARK: - Helpers

    private static func parseDate(_ str: String?) -> Date? {
        guard let str else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: str) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: str)
    }
}

// MARK: - Backup Error
enum BackupError: LocalizedError {
    case invalidFormat

    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "文件格式不正确，无法导入"
        }
    }
}

// MARK: - Model Dictionary Extensions (for JSON serialization)
extension WeddingProfile {
    func toDictionary() -> [String: Any] {
        [
            "id": id.uuidString,
            "weddingDate": ISO8601DateFormatter().string(from: weddingDate),
            "brideName": brideName,
            "groomName": groomName,
            "totalBudget": totalBudget
        ]
    }
}

extension TaskItem {
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id.uuidString,
            "title": title,
            "stage": stage,
            "category": category,
            "type": type,
            "daysBeforeWedding": daysBeforeWedding,
            "priority": priority,
            "isCompleted": isCompleted,
            "notes": notes,
            "reminderDaysBefore": reminderDaysBefore
        ]
        if let completedDate {
            dict["completedDate"] = ISO8601DateFormatter().string(from: completedDate)
        }
        return dict
    }
}

extension BudgetCategory {
    func toDictionary() -> [String: Any] {
        [
            "id": id.uuidString,
            "name": name,
            "budgetLimit": budgetLimit,
            "colorHex": colorHex,
            "order": order
        ]
    }
}

extension ExpenseRecord {
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id.uuidString,
            "amount": amount,
            "categoryName": categoryName,
            "date": ISO8601DateFormatter().string(from: date),
            "isPaid": isPaid,
            "note": note
        ]
        if let vendorName {
            dict["vendorName"] = vendorName
        }
        return dict
    }
}

extension Vendor {
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id.uuidString,
            "name": name,
            "serviceType": serviceType,
            "price": price,
            "status": status,
            "phone": phone,
            "notes": notes
        ]
        if let contactDate {
            dict["contactDate"] = ISO8601DateFormatter().string(from: contactDate)
        }
        return dict
    }
}

extension MaterialItem {
    func toDictionary() -> [String: Any] {
        [
            "id": id.uuidString,
            "name": name,
            "price": price,
            "quantity": quantity,
            "category": category,
            "channel": channel,
            "status": status,
            "notes": notes,
            "listType": listType
        ]
    }
}
