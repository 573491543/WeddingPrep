import SwiftUI

// MARK: - FloatingActionButton (浮动操作按钮)
struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void

    init(icon: String = "plus", action: @escaping () -> Void) {
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.primaryColor, AppTheme.accentColor],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: AppTheme.primaryColor.opacity(0.4), radius: 8, x: 0, y: 4)
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Tag View (通用标签)
struct TagView: View {
    let text: String
    var color: Color
    var textColor: Color
    var fontSize: Font

    init(text: String, color: Color = AppTheme.primaryColor.opacity(0.15), textColor: Color? = nil, fontSize: Font = AppTheme.smallCaption) {
        self.text = text
        self.color = color
        self.textColor = textColor ?? AppTheme.primaryColor
        self.fontSize = fontSize
    }

    var body: some View {
        Text(text)
            .font(fontSize)
            .foregroundColor(textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(color)
            )
    }
}
