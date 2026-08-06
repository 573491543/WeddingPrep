import SwiftUI

// MARK: - RingChartView (环形进度图)
/// 多段环形图，用于展示任务完成率或预算占比
struct RingChartView: View {
    let segments: [RingSegment]
    let lineWidth: CGFloat
    let centerText: String
    let centerSubtext: String?

    struct RingSegment: Identifiable {
        let id = UUID()
        let value: Double       // 占比 (0~1)
        let color: Color
        let label: String
    }

    init(segments: [RingSegment], lineWidth: CGFloat = 18, centerText: String, centerSubtext: String? = nil) {
        self.segments = segments
        self.lineWidth = lineWidth
        self.centerText = centerText
        self.centerSubtext = centerSubtext
    }

    var body: some View {
        ZStack {
            // 背景环
            Circle()
                .stroke(Color.gray.opacity(0.12), lineWidth: lineWidth)

            // 各段弧
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = (min(size.width, size.height) - lineWidth) / 2

                var startAngle = -Double.pi / 2  // 从顶部开始

                for segment in segments {
                    let angle = segment.value * 2 * Double.pi
                    let endAngle = startAngle + angle

                    var path = Path()
                    path.addArc(
                        center: center,
                        radius: radius,
                        startAngle: Angle.radians(startAngle),
                        endAngle: Angle.radians(endAngle),
                        clockwise: false
                    )

                    context.stroke(path, with: .color(segment.color), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

                    startAngle = endAngle
                }
            }
            .aspectRatio(1, contentMode: .fit)

            // 中心文字
            VStack(spacing: 2) {
                Text(centerText)
                    .font(AppTheme.mediumNumber)
                    .foregroundColor(AppTheme.primaryText)
                if let subtext = centerSubtext {
                    Text(subtext)
                        .font(AppTheme.smallCaption)
                        .foregroundColor(AppTheme.secondaryText)
                }
            }
        }
    }
}

// MARK: - Simple Progress Ring (单段进度环)
struct ProgressRingView: View {
    let progress: Double  // 0.0 ~ 1.0
    let lineWidth: CGFloat
    let color: Color
    let centerText: String?

    init(progress: Double, lineWidth: CGFloat = 12, color: Color = AppTheme.primaryColor, centerText: String? = nil) {
        self.progress = min(max(progress, 0), 1)
        self.lineWidth = lineWidth
        self.color = color
        self.centerText = centerText
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.12), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))

            if let centerText {
                Text(centerText)
                    .font(AppTheme.headline)
                    .foregroundColor(AppTheme.primaryText)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
