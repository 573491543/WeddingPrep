import Foundation

// MARK: - DateHelper (日期计算工具)
enum DateHelper {

    // MARK: - Wedding Countdown

    /// 计算距婚礼天数
    static func daysUntilWedding(weddingDate: Date) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let wedding = calendar.startOfDay(for: weddingDate)
        let diff = calendar.dateComponents([.day], from: today, to: wedding).day ?? 0
        return diff
    }

    /// 婚礼倒计时文本
    static func weddingCountdownText(weddingDate: Date) -> String {
        let days = daysUntilWedding(weddingDate: weddingDate)
        if days > 0 {
            return "\(days)天后"
        } else if days == 0 {
            return "就在今天"
        } else {
            return "已过 \(-days) 天"
        }
    }

    // MARK: - Date Formatting

    /// 格式化为 "X月X日 周X"
    static func formatChineseDate(_ date: Date) -> String {
        let calendar = Calendar(identifier: .gregorian)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        let weekday = formatWeekday(date)
        return "\(month)月\(day)日 \(weekday)"
    }

    /// 格式化为 "X月X日"
    static func formatShortDate(_ date: Date) -> String {
        let calendar = Calendar(identifier: .gregorian)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        return "\(month)月\(day)日"
    }

    /// 格式化为 "YYYY年X月X日"
    static func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: date)
    }

    /// 格式化为 "YYYY-MM-DD"
    static func formatISODate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    /// 周几文本
    static func formatWeekday(_ date: Date) -> String {
        let calendar = Calendar(identifier: .gregorian)
        let weekday = calendar.component(.weekday, from: date)
        let weekdays = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        return weekdays[weekday - 1]
    }

    // MARK: - Relative Time

    /// 相对今天的倒计时文本（基于传入天数）
    static func relativeDaysText(days: Int) -> String {
        if days > 0 {
            return "\(days)天后"
        } else if days == 0 {
            return "今天"
        } else {
            return "已逾期\(-days)天"
        }
    }

    // MARK: - Task Due Date

    /// 根据婚礼日期和距婚礼天数计算截止日期
    static func dueDate(weddingDate: Date, daysBeforeWedding: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -daysBeforeWedding, to: weddingDate) ?? weddingDate
    }

    /// 计算截止日期距今天的天数
    static func daysFromToday(dueDate: Date) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let due = calendar.startOfDay(for: dueDate)
        return calendar.dateComponents([.day], from: today, to: due).day ?? 0
    }

    // MARK: - Time Grouping (for Reminder Center)

    enum TimeGroup: String, CaseIterable {
        case thisWeek = "本周内"
        case thisMonth = "本月内"
        case later = "更远"

        /// 根据日期判断属于哪个分组
        static func group(for date: Date) -> TimeGroup {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let target = calendar.startOfDay(for: date)

            // 计算本周六（本周最后一天）
            // weekday: 1=Sunday, 7=Saturday
            let weekday = calendar.component(.weekday, from: today)
            let daysUntilSaturday = (7 - weekday + 7) % 7
            let endOfWeek = calendar.date(byAdding: .day, value: daysUntilSaturday, to: today)!

            // 计算本月最后一天（下月1号的前一天）
            let firstOfCurrentMonth = calendar.date(byAdding: .day, value: -(calendar.component(.day, from: today) - 1), to: today)!
            let firstOfNextMonth = calendar.date(byAdding: .month, value: 1, to: firstOfCurrentMonth)!
            let lastDayOfCurrentMonth = calendar.date(byAdding: .second, value: -1, to: firstOfNextMonth)!

            if target <= endOfWeek {
                return .thisWeek
            } else if target <= lastDayOfCurrentMonth {
                return .thisMonth
            } else {
                return .later
            }
        }
    }

    // MARK: - Currency Formatting

    /// 格式化金额 "¥X,XXX"
    static func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.currencySymbol = "¥"
        formatter.maximumFractionDigits = 0
        let number = NSNumber(value: amount)
        return formatter.string(from: number) ?? "¥\(Int(amount))"
    }

    /// 格式化金额（带小数）
    static func formatCurrencyDecimal(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.currencySymbol = "¥"
        formatter.maximumFractionDigits = 2
        let number = NSNumber(value: amount)
        return formatter.string(from: number) ?? "¥\(amount)"
    }

    // MARK: - Percentage

    /// 计算百分比并格式化
    static func formatPercent(_ numerator: Double, denominator: Double) -> String {
        guard denominator > 0 else { return "0%" }
        let percent = (numerator / denominator) * 100
        return String(format: "%.1f%%", percent)
    }

    static func percentValue(_ numerator: Double, denominator: Double) -> Double {
        guard denominator > 0 else { return 0 }
        return (numerator / denominator) * 100
    }
}
