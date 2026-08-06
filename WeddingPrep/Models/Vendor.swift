import Foundation
import SwiftData

@Model
final class Vendor {
    var id: UUID
    var name: String
    var serviceType: String   // VendorServiceType.rawValue
    var price: Double
    var status: String        // VendorStatus.rawValue
    var contactDate: Date?
    var phone: String
    var notes: String
    var createdAt: Date
    var updatedAt: Date

    init(
        name: String,
        serviceType: String = VendorServiceType.other.rawValue,
        price: Double = 0,
        status: String = VendorStatus.intentional.rawValue,
        contactDate: Date? = nil,
        phone: String = "",
        notes: String = ""
    ) {
        self.id = UUID()
        self.name = name
        self.serviceType = serviceType
        self.price = price
        self.status = status
        self.contactDate = contactDate
        self.phone = phone
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var statusEnum: VendorStatus {
        VendorStatus(rawValue: status) ?? .intentional
    }
}
