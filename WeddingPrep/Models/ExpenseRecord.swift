import Foundation
import SwiftData

@Model
final class ExpenseRecord {
    var id: UUID
    var amount: Double
    var categoryName: String
    var date: Date
    var isPaid: Bool
    var note: String
    var vendorName: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        amount: Double,
        categoryName: String,
        date: Date = Date(),
        isPaid: Bool = false,
        note: String = "",
        vendorName: String? = nil
    ) {
        self.id = UUID()
        self.amount = amount
        self.categoryName = categoryName
        self.date = date
        self.isPaid = isPaid
        self.note = note
        self.vendorName = vendorName
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
