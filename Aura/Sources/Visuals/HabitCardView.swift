import SwiftUI
import SwiftData

/// A glass habit card with a context/tap menu to trigger the sacred charging view.
struct HabitCardView: View {
    @Bindable var habit: HabitModel
    let delete: () -> Void
    let onTriggerRitual: () -> Void

    private var tint: Color { Color(auraHex: habit.colorHex) }

    var body: some View {
        Menu {
            Button(action: onTriggerRitual) {
                Label(habit.isComplete ? "重新儀式" : "進行儀式", systemImage: "bolt.shield.fill")
            }
            Button(role: .destructive, action: delete) {
                Label("Delete ritual", systemImage: "trash")
            }
        } label: {
            // 卡片本體視圖
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top) {
                    LiquidIcon(symbolName: habit.iconName, tint: tint, progress: habit.progress)
                    Spacer()
                    Image(systemName: "ellipsis")
                        .frame(width: 38, height: 38)
                        .foregroundStyle(.white.opacity(0.6))
                }

                Text(habit.title)
                    .font(.title2.weight(.bold))

                HStack(alignment: .lastTextBaseline) {
                    Text("\(Int(habit.progress * 100))%")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                    Spacer()
                    Text(habit.isComplete ? "CHARGED" : "TAP TO ENGAGE")
                        .font(.caption2.weight(.bold))
                        .tracking(1.2)
                        .foregroundStyle(tint)
                }

                GeometryReader { proxy in
                    Capsule()
                        .fill(.white.opacity(0.12))
                        .overlay(alignment: .leading) {
                            Capsule()
                                .fill(LinearGradient(colors: [tint.opacity(0.55), tint, .white], startPoint: .leading, endPoint: .trailing))
                                .frame(width: proxy.size.width * habit.progress)
                                .shadow(color: tint, radius: 10)
                        }
                }
                .frame(height: 9)
            }
            .padding(22)
            .background(glassSurface)
            .contentShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        }
        .buttonStyle(.plain) // 移除 Menu 預設的按鈕高亮行為
    }

    private var glassSurface: some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(tint.opacity(habit.isComplete ? 0.9 : 0.38), lineWidth: habit.isComplete ? 1.5 : 1)
            }
            .shadow(color: tint.opacity(habit.isComplete ? 0.48 : 0.16), radius: habit.isComplete ? 25 : 12)
    }
}

private struct LiquidIcon: View {
    let symbolName: String
    let tint: Color
    let progress: Double

    var body: some View {
        Image(systemName: symbolName)
            .symbolRenderingMode(.hierarchical)
            .font(.system(size: 28, weight: .medium))
            .foregroundStyle(.white, tint)
            .frame(width: 58, height: 58)
            .background(tint.opacity(0.16 + progress * 0.28), in: Circle())
            .overlay(Circle().stroke(.white.opacity(0.35)))
            .shadow(color: tint.opacity(progress), radius: 12)
    }
}