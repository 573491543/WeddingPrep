import SwiftUI

// MARK: - FilterChipView (筛选标签)
struct FilterChipView: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTheme.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : AppTheme.secondaryText)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(isSelected ? AppTheme.primaryColor : Color.gray)
                        .opacity(isSelected ? 1.0 : 0.1)
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - FilterChipScrollView (横向滚动筛选条)
struct FilterChipScrollView: View {
    let titles: [String]
    @Binding var selectedIndex: Int

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(titles.indices, id: \.self) { index in
                    FilterChipView(
                        title: titles[index],
                        isSelected: selectedIndex == index
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedIndex = index
                        }
                    }
                }
            }
            .padding(.horizontal, 2)
        }
    }
}
