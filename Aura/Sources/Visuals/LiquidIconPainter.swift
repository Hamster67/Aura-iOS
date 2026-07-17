import SwiftUI
import CoreMotion

/// The three deliberately soft, single-line Aura glyphs.
enum LiquidIconKind: String, CaseIterable, Identifiable {
    case water, meditate, book
    var id: String { rawValue }
    var title: String { rawValue == "water" ? "Drink water" : rawValue == "meditate" ? "Meditate" : "Read" }
    var systemFallback: String { rawValue == "water" ? "drop" : rawValue == "meditate" ? "figure.mind.and.body" : "book" }
}

/// Motion is deliberately filtered to avoid noisy gradients and unnecessary view updates.
final class LiquidIconMotion: ObservableObject {
    @Published private(set) var tilt = CGSize.zero
    private let manager = CMMotionManager()

    init() {
        guard manager.isDeviceMotionAvailable else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 30.0
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let gravity = motion?.gravity else { return }
            let target = CGSize(width: gravity.x * 24, height: -gravity.y * 24)
            // Low-pass filter: liquid follows the device, rather than jittering with it.
            self?.tilt = CGSize(width: (self?.tilt.width ?? 0) * 0.82 + target.width * 0.18,
                                height: (self?.tilt.height ?? 0) * 0.82 + target.height * 0.18)
        }
    }

    deinit { manager.stopDeviceMotionUpdates() }
}

/// A neon tube glyph. Its gradient shifts toward the physical bottom of a tilted phone.
struct LiquidIconPainter: View {
    let kind: LiquidIconKind
    let color: Color
    var progress: Double = 0
    @StateObject private var motion = LiquidIconMotion()

    var body: some View {
        GeometryReader { proxy in
            let path = LiquidGlyph(kind: kind).path(in: CGRect(origin: .zero, size: proxy.size).insetBy(dx: 6, dy: 6))
            let flow = UnitPoint(x: 0.5 + motion.tilt.width / max(proxy.size.width, 1),
                                 y: 0.08 + motion.tilt.height / max(proxy.size.height, 1))
            let settled = UnitPoint(x: 0.5 - motion.tilt.width / max(proxy.size.width, 1),
                                    y: 0.92 + motion.tilt.height / max(proxy.size.height, 1))

            ZStack {
                path.stroke(color.opacity(0.23), style: StrokeStyle(lineWidth: 13, lineCap: .round, lineJoin: .round))
                    .blur(radius: 7)
                path.stroke(LinearGradient(colors: [.white.opacity(0.92), color, color.opacity(0.32)], startPoint: flow, endPoint: settled), style: StrokeStyle(lineWidth: 7, lineCap: .round, lineJoin: .round))
                path.stroke(.white.opacity(0.75), style: StrokeStyle(lineWidth: 1.1, lineCap: .round, lineJoin: .round))
            }
            .shadow(color: color.opacity(0.45 + progress * 0.35), radius: 10 + progress * 8)
        }
        .accessibilityLabel(kind.title)
    }
}

private struct LiquidGlyph: Shape {
    let kind: LiquidIconKind

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let x = rect.minX
        let y = rect.minY

        switch kind {
        case .water:
            path.move(to: CGPoint(x: x + w * 0.5, y: y))
            path.addCurve(to: CGPoint(x: x + w * 0.18, y: y + h * 0.57), control1: CGPoint(x: x + w * 0.33, y: y + h * 0.24), control2: CGPoint(x: x + w * 0.18, y: y + h * 0.38))
            path.addCurve(to: CGPoint(x: x + w * 0.5, y: y + h), control1: CGPoint(x: x + w * 0.18, y: y + h * 0.82), control2: CGPoint(x: x + w * 0.32, y: y + h))
            path.addCurve(to: CGPoint(x: x + w * 0.82, y: y + h * 0.57), control1: CGPoint(x: x + w * 0.68, y: y + h), control2: CGPoint(x: x + w * 0.82, y: y + h * 0.82))
            path.addCurve(to: CGPoint(x: x + w * 0.5, y: y), control1: CGPoint(x: x + w * 0.82, y: y + h * 0.38), control2: CGPoint(x: x + w * 0.67, y: y + h * 0.24))
        case .meditate:
            path.addEllipse(in: CGRect(x: x + w * 0.39, y: y + h * 0.03, width: w * 0.22, height: h * 0.22))
            path.move(to: CGPoint(x: x + w * 0.5, y: y + h * 0.3))
            path.addCurve(to: CGPoint(x: x + w * 0.23, y: y + h * 0.72), control1: CGPoint(x: x + w * 0.38, y: y + h * 0.43), control2: CGPoint(x: x + w * 0.25, y: y + h * 0.49))
            path.addCurve(to: CGPoint(x: x + w * 0.77, y: y + h * 0.72), control1: CGPoint(x: x + w * 0.37, y: y + h * 0.87), control2: CGPoint(x: x + w * 0.63, y: y + h * 0.87))
            path.addCurve(to: CGPoint(x: x + w * 0.5, y: y + h * 0.3), control1: CGPoint(x: x + w * 0.75, y: y + h * 0.49), control2: CGPoint(x: x + w * 0.62, y: y + h * 0.43))
        case .book:
            path.move(to: CGPoint(x: x + w * 0.5, y: y + h * 0.14))
            path.addCurve(to: CGPoint(x: x + w * 0.1, y: y + h * 0.18), control1: CGPoint(x: x + w * 0.36, y: y + h * 0.04), control2: CGPoint(x: x + w * 0.17, y: y + h * 0.1))
            path.addLine(to: CGPoint(x: x + w * 0.1, y: y + h * 0.83))
            path.addCurve(to: CGPoint(x: x + w * 0.5, y: y + h * 0.88), control1: CGPoint(x: x + w * 0.24, y: y + h * 0.76), control2: CGPoint(x: x + w * 0.39, y: y + h * 0.82))
            path.addCurve(to: CGPoint(x: x + w * 0.9, y: y + h * 0.83), control1: CGPoint(x: x + w * 0.61, y: y + h * 0.82), control2: CGPoint(x: x + w * 0.76, y: y + h * 0.76))
            path.addLine(to: CGPoint(x: x + w * 0.9, y: y + h * 0.18))
            path.addCurve(to: CGPoint(x: x + w * 0.5, y: y + h * 0.14), control1: CGPoint(x: x + w * 0.83, y: y + h * 0.1), control2: CGPoint(x: x + w * 0.64, y: y + h * 0.04))
            path.move(to: CGPoint(x: x + w * 0.5, y: y + h * 0.14))
            path.addLine(to: CGPoint(x: x + w * 0.5, y: y + h * 0.88))
        }
        return path
    }
}
