import SwiftUI

// MARK: - EmptyStateView (空状态占位)
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String?

    init(icon: String = "tray", title: String, subtitle: String? = nil) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(AppTheme.secondaryText.opacity(0.5))

            Text(title)
                .font(AppTheme.headline)
                .foregroundColor(AppTheme.secondaryText)

            if let subtitle {
                Text(subtitle)
                    .font(AppTheme.caption)
                    .foregroundColor(AppTheme.secondaryText.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}
