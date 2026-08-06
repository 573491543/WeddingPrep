import SwiftUI

// MARK: - ProgressBarView (进度条)
struct ProgressBarView: View {
    let progress: Double     // 0.0 ~ 1.0
    let height: CGFloat
    let color: Color
    let trackColor: Color
    var showMarker: Bool     // 是否显示标记点

    init(
        progress: Double,
        height: CGFloat = 8,
        color: Color = AppTheme.primaryColor,
        trackColor: Color = Color.gray.opacity(0.15),
        showMarker: Bool = false
    ) {
        self.progress = min(max(progress, 0), 1)
        self.height = height
        self.color = color
        self.trackColor = trackColor
        self.showMarker = showMarker
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 轨道
                Capsule()
                    .fill(trackColor)
                    .frame(height: height)

                // 进度填充
                Capsule()
                    .fill(color)
                    .frame(width: max(0, geometry.size.width * progress), height: height)
                    .animation(.easeInOut(duration: 0.3), value: progress)

                // 标记点
                if showMarker && progress > 0 && progress < 1 {
                    Circle()
                        .fill(color)
                        .frame(width: height + 4, height: height + 4)
                        .offset(x: max(0, geometry.size.width * progress) - (height + 4) / 2)
                }
            }
        }
        .frame(height: height)
    }
}

// MARK: - SegmentedProgressBar (分段进度条)
/// 用于显示已完成/进行中/逾期等多段进度
struct SegmentedProgressBarView: View {
    struct Segment: Identifiable {
        let id = UUID()
        let value: Double     // 占比 0~1
        let color: Color
    }

    let segments: [Segment]
    let height: CGFloat

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                ForEach(segments) { segment in
                    Rectangle()
                        .fill(segment.color)
                        .frame(width: geometry.size.width * segment.value)
                }
                Spacer(minLength: 0)
            }
            .clipShape(Capsule())
            .background(Capsule().fill(Color.gray.opacity(0.12)))
        }
        .frame(height: height)
    }
}
