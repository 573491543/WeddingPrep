import Foundation
import SwiftUI

// MARK: - Task Stage (任务时间节点)
enum TaskStage: String, CaseIterable, Codable {
    case sixMonthsBefore = "婚前6个月"
    case threeMonthsBefore = "婚前3个月"
    case oneMonthBefore = "婚前1个月"
    case oneWeekBefore = "婚前1周"
    case weddingDay = "婚礼当天"
    case custom = "自定义"

    /// 对应的距婚礼天数（用于预填任务的 daysBeforeWedding 默认值）
    var defaultDaysBefore: Int {
        switch self {
        case .sixMonthsBefore: return 180
        case .threeMonthsBefore: return 90
        case .oneMonthBefore: return 30
        case .oneWeekBefore: return 7
        case .weddingDay: return 0
        case .custom: return 60
        }
    }
}

// MARK: - Task Category (任务类别)
enum TaskCategory: String, CaseIterable, Codable {
    case photography = "摄影摄像"
    case dress = "婚纱礼服"
    case banquet = "婚宴筹备"
    case decoration = "婚庆布置"
    case family = "亲友沟通"
    case documents = "证件办理"
    case beauty = "跟妆造型"
    case travel = "蜜月旅行"
    case other = "其他"
}

// MARK: - Task Type (任务类型)
enum TaskType: String, CaseIterable, Codable {
    case task = "任务"
    case memo = "备忘"
}

// MARK: - Priority (优先级)
enum Priority: Int, CaseIterable, Codable {
    case high = 0
    case medium = 1
    case low = 2

    var label: String {
        switch self {
        case .high: return "高"
        case .medium: return "中"
        case .low: return "低"
        }
    }

    var color: Color {
        switch self {
        case .high: return AppTheme.dangerColor
        case .medium: return AppTheme.warningColor
        case .low: return AppTheme.successColor
        }
    }

    var dotSize: CGFloat { 8 }
}

// MARK: - Vendor Status (商家状态)
enum VendorStatus: String, CaseIterable, Codable {
    case signed = "已签约"
    case intentional = "意向中"
    case contacted = "已洽谈"
    case eliminated = "已淘汰"

    var color: Color {
        switch self {
        case .signed: return AppTheme.successColor
        case .intentional: return AppTheme.warningColor
        case .contacted: return AppTheme.infoColor
        case .eliminated: return Color.secondary
        }
    }

    var icon: String {
        switch self {
        case .signed: return "checkmark.seal.fill"
        case .intentional: return "hand.thumbsup.fill"
        case .contacted: return "person.crop.circle.badge.questionmark"
        case .eliminated: return "xmark.circle.fill"
        }
    }
}

// MARK: - Vendor Service Type (商家服务类型)
enum VendorServiceType: String, CaseIterable, Codable {
    case dress = "婚纱礼服"
    case photography = "摄影摄像"
    case banquet = "婚宴酒店"
    case decoration = "婚庆布置"
    case makeup = "跟妆造型"
    case mc = "婚礼司仪"
    case car = "婚车租赁"
    case flower = "花艺布置"
    case other = "其他"
}

// MARK: - Material Category (物资分类)
enum MaterialCategory: String, CaseIterable, Codable {
    case roomDecor = "婚房布置"
    case candy = "喜糖喜品"
    case bride = "新娘用品"
    case guest = "宾客用品"
    case ceremony = "仪式道具"
    case other = "其他"
}

// MARK: - Material Channel (采购渠道)
enum MaterialChannel: String, CaseIterable, Codable {
    case taobao = "淘宝"
    case jd = "京东"
    case pdd = "拼多多"
    case offline = "线下商场"
    case diy = "自制/DIY"
    case other = "其他"
}

// MARK: - Material Status (采购状态)
enum MaterialStatus: String, CaseIterable, Codable {
    case notPurchased = "未采购"
    case purchased = "已采购"

    var color: Color {
        switch self {
        case .notPurchased: return AppTheme.primaryColor
        case .purchased: return AppTheme.successColor
        }
    }
}

// MARK: - Material List Type (清单类型)
enum MaterialListType: String, CaseIterable, Codable {
    case purchase = "采购物资清单"
    case carry = "当日随身物品"
}

// MARK: - Budget Category Preset
enum BudgetCategoryPreset: String, CaseIterable, Codable {
    case banquet = "婚宴酒席"
    case dress = "婚纱礼服"
    case photography = "摄影摄像"
    case makeup = "跟妆造型"
    case decoration = "婚庆布置"
    case ring = "婚戒首饰"
    case travel = "蜜月旅行"
    case guestAccommodation = "亲友住宿"
    case other = "其他支出"

    var colorHex: String {
        switch self {
        case .banquet: return "#E8A0BF"
        case .dress: return "#7DCEA0"
        case .photography: return "#C8B6E2"
        case .makeup: return "#F7DC6F"
        case .decoration: return "#85C1E2"
        case .ring: return "#F1948A"
        case .travel: return "#82E0AA"
        case .guestAccommodation: return "#AED6F1"
        case .other: return "#D5DBDB"
        }
    }

    var defaultLimit: Double {
        switch self {
        case .banquet: return 80000
        case .dress: return 5000
        case .photography: return 8000
        case .makeup: return 3000
        case .decoration: return 10000
        case .ring: return 15000
        case .travel: return 20000
        case .guestAccommodation: return 5000
        case .other: return 5000
        }
    }
}
