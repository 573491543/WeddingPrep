import SwiftUI

// MARK: - App Theme (设计系统)
enum AppTheme {
    // MARK: - Colors (浅色模式)
    static let primaryColor = Color(hex: "#E8A0BF")          // 柔和粉
    static let secondaryColor = Color(hex: "#C8B6E2")        // 淡紫
    static let backgroundColor = Color(hex: "#FFF5F7")      // 极浅粉
    static let cardColor = Color.white                        // 卡片白
    static let successColor = Color(hex: "#7DCEA0")           // 薄荷绿
    static let warningColor = Color(hex: "#F7DC6F")          // 暖黄
    static let dangerColor = Color(hex: "#E74C3C")           // 珊瑚红
    static let infoColor = Color(hex: "#85C1E2")              // 淡蓝
    static let textColor = Color(hex: "#2C2C2C")             // 主文字
    static let secondaryTextColor = Color(hex: "#888888")    // 次要文字
    static let accentColor = Color(hex: "#D1789A")            // 强调色（深粉）

    // MARK: - Adaptive Colors (深色模式适配)
    static var bg: Color {
        Color(light: backgroundColor, dark: Color(hex: "#1A1A1A"))
    }
    static var cardBg: Color {
        Color(light: cardColor, dark: Color(hex: "#2C2C2C"))
    }
    static var primaryText: Color {
        Color(light: textColor, dark: Color(hex: "#E8E8E8"))
    }
    static var secondaryText: Color {
        Color(light: secondaryTextColor, dark: Color(hex: "#999999"))
    }

    // MARK: - Tab Colors
    static func tabColor(for tab: AppTab) -> Color {
        switch tab {
        case .home: return Color(hex: "#E8A0BF")
        case .timePlan: return Color(hex: "#C8B6E2")
        case .budget: return Color(hex: "#7DCEA0")
        case .vendor: return Color(hex: "#85C1E2")
        case .material: return Color(hex: "#F7DC6F")
        case .reminder: return Color(hex: "#F1948A")
        }
    }

    // MARK: - Fonts
    static let largeTitle = Font.system(size: 32, weight: .bold, design: .rounded)
    static let title = Font.system(size: 22, weight: .bold, design: .rounded)
    static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let body = Font.system(size: 15, weight: .regular, design: .rounded)
    static let caption = Font.system(size: 13, weight: .regular, design: .rounded)
    static let smallCaption = Font.system(size: 11, weight: .regular, design: .rounded)
    static let bigNumber = Font.system(size: 48, weight: .bold, design: .rounded)
    static let mediumNumber = Font.system(size: 28, weight: .bold, design: .rounded)

    // MARK: - Spacing & Radius
    static let cornerRadius: CGFloat = 16
    static let smallCornerRadius: CGFloat = 10
    static let cardPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 12
}

// MARK: - App Tab Definition
enum AppTab: Int, CaseIterable {
    case home = 0
    case timePlan
    case budget
    case vendor
    case material
    case reminder

    var title: String {
        switch self {
        case .home: return "首页"
        case .timePlan: return "时间规划"
        case .budget: return "预算管理"
        case .vendor: return "商家资源"
        case .material: return "物资清单"
        case .reminder: return "提醒中心"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .timePlan: return "calendar"
        case .budget: return "creditcard.fill"
        case .vendor: return "storefront.fill"  // Note: storefront.fill requires iOS 17
        case .material: return "list.clipboard.fill"
        case .reminder: return "bell.fill"
        }
    }

    var iconFallback: String {
        switch self {
        case .home: return "house.fill"
        case .timePlan: return "calendar"
        case .budget: return "creditcard.fill"
        case .vendor: return "mappin.circle.fill"  // fallback if storefront not available
        case .material: return "list.bullet.rectangle.fill"
        case .reminder: return "bell.fill"
        }
    }
}

// MARK: - Color Extensions
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 232, 160, 191)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    init(light: Color, dark: Color) {
        self = Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)
        })
    }
}

// MARK: - View Extension for Card Style
extension View {
    func cardStyle(background: Color = AppTheme.cardBg) -> some View {
        self
            .padding(AppTheme.cardPadding)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    func cardStylePlain(background: Color = AppTheme.cardBg) -> some View {
        self
            .padding(AppTheme.cardPadding)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
    }
}
