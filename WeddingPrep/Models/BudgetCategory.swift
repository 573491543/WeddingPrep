import Foundation
import SwiftData

@Model
final class BudgetCategory {
    var id: UUID
    var name: String
    var budgetLimit: Double
    var colorHex: String
    var order: Int
    var createdAt: Date

    init(
        name: String,
        budgetLimit: Double = 0,
        colorHex: String = "#E8A0BF",
        order: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.budgetLimit = budgetLimit
        self.colorHex = colorHex
        self.order = order
        self.createdAt = Date()
    }
}
