import SwiftUI

// MARK: - StatusBadge (状态标签)
struct StatusBadge: View {
    let text: String
    let color: Color

    init(text: String, color: Color = AppTheme.primaryColor) {
        self.text = text
        self.color = color
    }

    var body: some View {
        HStack(spacing: 3) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(text)
                .font(AppTheme.smallCaption)
                .foregroundColor(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(color.opacity(0.12))
        )
    }
}
