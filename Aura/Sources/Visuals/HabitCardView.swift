import SwiftUI
import SwiftData
import UIKit

/// A glass habit card charged through a deliberate long-press ritual.
struct HabitCardView: View {
    @Bindable var habit: HabitModel
    let delete: () -> Void
    let onChargeUpdate: (HabitModel, Double, Bool) -> Void

    @State private var isLongPressing = false
    @State private var chargingProgress = 0.0
    @State private var chargeTask: Task<Void, Never>?
    @State private var magnification = 1.0

    private let chargeDuration: TimeInterval = 3.2
    private var tint: Color { Color(auraHex: habit.colorHex) }
    private var displayedProgress: Double { max(habit.progress, chargingProgress) }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                LiquidIcon(symbolName: habit.iconName, tint: tint, progress: displayedProgress)
                Spacer()
                Menu {
                    Button("Delete ritual", role: .destructive, action: delete)
                } label: {
                    Image(systemName: "ellipsis")
                        .frame(width: 38, height: 38)
                }
            }

            Text(habit.title)
                .font(.title2.weight(.bold))

            HStack(alignment: .lastTextBaseline) {
                Text("\(Int(displayedProgress * 100))%")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                Spacer()
                Text(habit.isComplete ? "CHARGED" : "HOLD TO CHARGE")
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
                            .frame(width: proxy.size.width * displayedProgress)
                            .shadow(color: tint, radius: 10)
                    }
            }
            .frame(height: 9)
        }
        .padding(22)
        .background(glassSurface)
        .scaleEffect(1 + (magnification - 1) * 0.06)
        .contentShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        // 修正：將長按手勢分離，並改用更穩定的 DragGesture 來監聽觸摸狀態
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isLongPressing {
                        isLongPressing = true
                        beginCharging()
                    }
                }
                .onEnded { _ in
                    isLongPressing = false
                    endCharging()
                }
        )
        // 修正：捏合刪除手勢改用高優先級觸發，避免兩者衝突
        .highPriorityGesture(pinchToDeleteGesture)
        .onDisappear { chargeTask?.cancel() }
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

    private var pinchToDeleteGesture: some Gesture {
        MagnificationGesture()
            .onChanged { magnification = $0 }
            .onEnded { value in
                if value < 0.72 { delete() }
                withAnimation(.spring(response: 0.35, dampingFraction: 0.68)) { magnification = 1 }
            }
    }

    private func beginCharging() {
        guard !habit.isComplete, chargeTask == nil else { return }

        let feedback = UISelectionFeedbackGenerator()
        feedback.prepare()
        
        // 延續之前斷掉的進度，而不是每次都從 0 開始
        let startProgress = chargingProgress
        let startedAt = Date.now - (startProgress * chargeDuration)

        chargeTask = Task { @MainActor in
            while !Task.isCancelled && isLongPressing {
                let progress = min(1, Date.now.timeIntervalSince(startedAt) / chargeDuration)
                chargingProgress = progress
                habit.progress = progress
                feedback.selectionChanged()
                feedback.prepare()

                onChargeUpdate(habit, progress, true)
                if progress >= 1 {
                    chargeTask = nil
                    isLongPressing = false
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    onChargeUpdate(habit, 1, false)
                    return
                }

                try? await Task.sleep(nanoseconds: 40_000_000) // 縮短更新間隔，讓動畫漣漪更絲滑
            }
        }
    }

    private func endCharging() {
        chargeTask?.cancel()
        chargeTask = nil

        guard !habit.isComplete else { return }
        
        // 修正：如果放開手指時還沒滿，讓進度自然倒退回 0，而不是瞬間歸零
        withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) {
            chargingProgress = 0
            habit.progress = 0
        }
        onChargeUpdate(habit, 0, false)
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
}import SwiftUI
import SwiftData
import UIKit

/// A glass habit card charged through a deliberate long-press ritual.
struct HabitCardView: View {
    @Bindable var habit: HabitModel
    let delete: () -> Void
    let onChargeUpdate: (HabitModel, Double, Bool) -> Void

    @State private var isLongPressing = false
    @State private var chargingProgress = 0.0
    @State private var chargeTask: Task<Void, Never>?
    @State private var magnification = 1.0

    private let chargeDuration: TimeInterval = 3.2
    private var tint: Color { Color(auraHex: habit.colorHex) }
    private var displayedProgress: Double { max(habit.progress, chargingProgress) }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                LiquidIcon(symbolName: habit.iconName, tint: tint, progress: displayedProgress)
                Spacer()
                Menu {
                    Button("Delete ritual", role: .destructive, action: delete)
                } label: {
                    Image(systemName: "ellipsis")
                        .frame(width: 38, height: 38)
                }
            }

            Text(habit.title)
                .font(.title2.weight(.bold))

            HStack(alignment: .lastTextBaseline) {
                Text("\(Int(displayedProgress * 100))%")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                Spacer()
                Text(habit.isComplete ? "CHARGED" : "HOLD TO CHARGE")
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
                            .frame(width: proxy.size.width * displayedProgress)
                            .shadow(color: tint, radius: 10)
                    }
            }
            .frame(height: 9)
        }
        .padding(22)
        .background(glassSurface)
        .scaleEffect(1 + (magnification - 1) * 0.06)
        .contentShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        // 修正：將長按手勢分離，並改用更穩定的 DragGesture 來監聽觸摸狀態
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isLongPressing {
                        isLongPressing = true
                        beginCharging()
                    }
                }
                .onEnded { _ in
                    isLongPressing = false
                    endCharging()
                }
        )
        // 修正：捏合刪除手勢改用高優先級觸發，避免兩者衝突
        .highPriorityGesture(pinchToDeleteGesture)
        .onDisappear { chargeTask?.cancel() }
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

    private var pinchToDeleteGesture: some Gesture {
        MagnificationGesture()
            .onChanged { magnification = $0 }
            .onEnded { value in
                if value < 0.72 { delete() }
                withAnimation(.spring(response: 0.35, dampingFraction: 0.68)) { magnification = 1 }
            }
    }

    private func beginCharging() {
        guard !habit.isComplete, chargeTask == nil else { return }

        let feedback = UISelectionFeedbackGenerator()
        feedback.prepare()
        
        // 延續之前斷掉的進度，而不是每次都從 0 開始
        let startProgress = chargingProgress
        let startedAt = Date.now - (startProgress * chargeDuration)

        chargeTask = Task { @MainActor in
            while !Task.isCancelled && isLongPressing {
                let progress = min(1, Date.now.timeIntervalSince(startedAt) / chargeDuration)
                chargingProgress = progress
                habit.progress = progress
                feedback.selectionChanged()
                feedback.prepare()

                onChargeUpdate(habit, progress, true)
                if progress >= 1 {
                    chargeTask = nil
                    isLongPressing = false
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    onChargeUpdate(habit, 1, false)
                    return
                }

                try? await Task.sleep(nanoseconds: 40_000_000) // 縮短更新間隔，讓動畫漣漪更絲滑
            }
        }
    }

    private func endCharging() {
        chargeTask?.cancel()
        chargeTask = nil

        guard !habit.isComplete else { return }
        
        // 修正：如果放開手指時還沒滿，讓進度自然倒退回 0，而不是瞬間歸零
        withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) {
            chargingProgress = 0
            habit.progress = 0
        }
        onChargeUpdate(habit, 0, false)
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