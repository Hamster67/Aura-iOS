import ActivityKit
import WidgetKit
import SwiftUI

/// Widget extension presentation for AuraActivityAttributes. All animation is
/// local SwiftUI interpolation; the app throttles ActivityKit snapshots to 4 Hz.
struct AuraWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AuraActivityAttributes.self) { context in
            LockScreenChamber(state: context.state)
                .activityBackgroundTint(.black.opacity(0.72))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) { ExpandedChamber(state: context.state) }
            } compactLeading: {
                Image(systemName: "drop.fill").font(.caption).foregroundStyle(neon(context.state.neonColorHex))
            } compactTrailing: {
                LiquidRing(progress: context.state.currentProgress, color: neon(context.state.neonColorHex)).frame(width: 19, height: 19)
            } minimal: {
                LiquidRing(progress: context.state.currentProgress, color: neon(context.state.neonColorHex)).frame(width: 16, height: 16)
            }
        }
    }

    private func neon(_ hex: String) -> Color { Color(auraHex: hex) }
}

private struct LockScreenChamber: View {
    let state: AuraActivityAttributes.ContentState
    private var color: Color { Color(auraHex: state.neonColorHex) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("正在注入：\(state.habitName)").font(.headline)
            LiquidBar(progress: state.currentProgress, color: color).frame(height: 10)
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct ExpandedChamber: View {
    let state: AuraActivityAttributes.ContentState
    private var color: Color { Color(auraHex: state.neonColorHex) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("正在注入：\(state.habitName)").font(.headline.weight(.semibold))
            LiquidBar(progress: state.currentProgress, color: color).frame(height: 13)
            Text("\(Int(state.currentProgress * 100))% charged").font(.caption).foregroundStyle(.white.opacity(0.62))
        }
        .padding(.horizontal, 20).padding(.vertical, 14)
        .background(.thinMaterial, in: Capsule())
    }
}

private struct LiquidBar: View {
    let progress: Double
    let color: Color
    var body: some View {
        GeometryReader { proxy in
            Capsule().fill(.white.opacity(0.13)).overlay(alignment: .leading) {
                Capsule().fill(LinearGradient(colors: [color.opacity(0.45), color, .white], startPoint: .leading, endPoint: .trailing))
                    .frame(width: proxy.size.width * min(max(progress, 0), 1))
                    .shadow(color: color.opacity(0.9), radius: 11)
                    .animation(.smooth, value: progress)
            }
        }
    }
}

private struct LiquidRing: View {
    let progress: Double
    let color: Color
    var body: some View {
        Circle().stroke(.white.opacity(0.18), lineWidth: 3).overlay {
            Circle().trim(from: 0, to: min(max(progress, 0), 1)).stroke(LinearGradient(colors: [color, .white], startPoint: .topLeading, endPoint: .bottomTrailing), style: StrokeStyle(lineWidth: 3, lineCap: .round)).rotationEffect(.degrees(-90)).shadow(color: color, radius: 4)
        }
    }
}

private extension Color {
    init(auraHex hex: String) {
        let value = UInt64(hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted), radix: 16) ?? 0
        self.init(.sRGB, red: Double((value >> 16) & 0xFF) / 255, green: Double((value >> 8) & 0xFF) / 255, blue: Double(value & 0xFF) / 255, opacity: 1)
    }
}
