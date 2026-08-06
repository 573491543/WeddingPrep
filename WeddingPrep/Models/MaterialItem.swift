import Foundation
import SwiftData

@Model
final class MaterialItem {
    var id: UUID
    var name: String
    var price: Double
    var quantity: Int
    var category: String      // MaterialCategory.rawValue
    var channel: String       // MaterialChannel.rawValue
    var status: String        // MaterialStatus.rawValue
    var notes: String
    var listType: String      // MaterialListType.rawValue
    var createdAt: Date
    var updatedAt: Date

    init(
        name: String,
        price: Double = 0,
        quantity: Int = 1,
        category: String = MaterialCategory.other.rawValue,
        channel: String = MaterialChannel.taobao.rawValue,
        status: String = MaterialStatus.notPurchased.rawValue,
        notes: String = "",
        listType: String = MaterialListType.purchase.rawValue
    ) {
        self.id = UUID()
        self.name = name
        self.price = price
        self.quantity = quantity
        self.category = category
        self.channel = channel
        self.status = status
        self.notes = notes
        self.listType = listType
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var statusEnum: MaterialStatus {
        MaterialStatus(rawValue: status) ?? .notPurchased
    }

    var totalPrice: Double {
        price * Double(quantity)
    }
}
