import SwiftUI

// MARK: - SearchBarView (搜索栏)
struct SearchBarView: View {
    @Binding var text: String
    var placeholder: String

    init(text: Binding<String>, placeholder: String = "搜索") {
        self._text = text
        self.placeholder = placeholder
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppTheme.secondaryText)
                .font(.system(size: 16))

            TextField(placeholder, text: $text)
                .font(AppTheme.body)
                .foregroundColor(AppTheme.primaryText)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppTheme.secondaryText)
                        .font(.system(size: 16))
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius, style: .continuous)
                .fill(AppTheme.cardBg)
                .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 1)
        )
    }
}
