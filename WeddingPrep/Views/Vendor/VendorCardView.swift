import SwiftUI

struct VendorCardView: View {
    let vendor: Vendor
    let onTap: () -> Void

    private var statusEnum: VendorStatus {
        VendorStatus(rawValue: vendor.status) ?? .intentional
    }

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // Status icon
                ZStack {
                    Circle()
                        .fill(statusEnum.color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: statusEnum.icon)
                        .font(.system(size: 18))
                        .foregroundColor(statusEnum.color)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(vendor.name)
                            .font(AppTheme.headline)
                            .foregroundColor(AppTheme.primaryText)
                        Spacer()
                        Text(DateHelper.formatCurrency(vendor.price))
                            .font(AppTheme.title)
                            .foregroundColor(AppTheme.accentColor)
                    }

                    // Tags row
                    HStack(spacing: 6) {
                        TagView(text: vendor.serviceType, color: AppTheme.infoColor.opacity(0.15), textColor: AppTheme.infoColor)
                        StatusBadge(text: statusEnum.rawValue, color: statusEnum.color)
                    }

                    // Contact date
                    if let contactDate = vendor.contactDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 11))
                                .foregroundColor(AppTheme.secondaryText)
                            Text("已洽谈 \(DateHelper.formatShortDate(contactDate))")
                                .font(AppTheme.smallCaption)
                                .foregroundColor(AppTheme.secondaryText)
                        }
                    }

                    // Phone
                    if !vendor.phone.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "phone.fill")
                                .font(.system(size: 11))
                                .foregroundColor(AppTheme.secondaryText)
                            Text(vendor.phone)
                                .font(AppTheme.smallCaption)
                                .foregroundColor(AppTheme.secondaryText)
                        }
                    }

                    // Notes
                    if !vendor.notes.isEmpty {
                        Text(vendor.notes)
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
