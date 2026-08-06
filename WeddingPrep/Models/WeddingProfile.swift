import Foundation
import SwiftData

@Model
final class WeddingProfile {
    var id: UUID
    var weddingDate: Date
    var brideName: String
    var groomName: String
    var totalBudget: Double
    var createdAt: Date
    var updatedAt: Date

    init(
        weddingDate: Date = Calendar.current.date(byAdding: .month, value: 9, to: Date()) ?? Date(),
        brideName: String = "",
        groomName: String = "",
        totalBudget: Double = 100000
    ) {
        self.id = UUID()
        self.weddingDate = weddingDate
        self.brideName = brideName
        self.groomName = groomName
        self.totalBudget = totalBudget
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
