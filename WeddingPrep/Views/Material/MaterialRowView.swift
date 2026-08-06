import SwiftUI

struct MaterialRowView: View {
    let material: MaterialItem
    let onToggle: () -> Void
    let onTap: () -> Void

    private var statusEnum: MaterialStatus {
        MaterialStatus(rawValue: material.status) ?? .notPurchased
    }

    private var isPurchased: Bool {
        statusEnum == .purchased
    }

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // Checkbox
                Button {
                    onToggle()
                } label: {
                    Image(systemName: isPurchased ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundColor(isPurchased ? AppTheme.successColor : AppTheme.secondaryText.opacity(0.4))
                }
                .buttonStyle(ScaleButtonStyle())

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(material.name)
                            .font(AppTheme.headline)
                            .foregroundColor(isPurchased ? AppTheme.secondaryText : AppTheme.primaryText)
                            .strikethrough(isPurchased)
                        Spacer()
                        Text(DateHelper.formatCurrency(material.totalPrice))
                            .font(AppTheme.title)
                            .foregroundColor(AppTheme.accentColor)
                    }

                    // Tags row
                    HStack(spacing: 6) {
                        TagView(text: "x\(material.quantity)", color: AppTheme.primaryColor.opacity(0.15), textColor: AppTheme.primaryColor)
                        TagView(text: material.category, color: AppTheme.secondaryColor.opacity(0.15), textColor: AppTheme.secondaryColor)
                        TagView(text: material.channel, color: AppTheme.infoColor.opacity(0.15), textColor: AppTheme.infoColor)
                        StatusBadge(text: statusEnum.rawValue, color: statusEnum.color)
                    }

                    // Notes
                    if !material.notes.isEmpty {
                        Text(material.notes)
                            .font(AppTheme.smallCaption)
                            .foregroundColor(AppTheme.secondaryText.opacity(0.8))
                            .lineLimit(2)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(AppTheme.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                    .fill(AppTheme.cardBg)
                    .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
