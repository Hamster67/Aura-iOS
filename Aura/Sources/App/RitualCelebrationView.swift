import SwiftUI
import UIKit

struct RitualCelebrationView: View {
    @Bindable var habit: HabitModel
    let method: CompletionMethod
    let onChargeUpdate: (Double, Bool) -> Void
    @Environment(\.dismiss) private var dismiss

    // 互動內部狀態
    @State private var progress = 0.0
    @State private var isInteracting = false
    @State private var chargeTask: Task<Void, Never>?
    @State private var tapCount = 0
    @State private var scale: CGFloat = 1.0
    @State private var isCelebrating = false
    
    // 煙火粒子動畫狀態
    @State private var particleAnimation = false

    private var tint: Color { Color(auraHex: habit.colorHex) }
    private let chargeDuration: TimeInterval = 3.0

    var body: some View {
        ZStack {
            // 黑色沉浸式背景加液態模糊
            Color.black.ignoresSafeArea()
            
            // 唯美霓虹光暈
            Circle()
                .fill(tint.opacity(0.15 + (progress * 0.2)))
                .frame(width: 400, height: 400)
                .blur(radius: 60)
                .offset(y: -50)
                .scaleEffect(isInteracting ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.5), value: isInteracting)

            VStack(spacing: 40) {
                // 頂部關閉按鈕
                HStack {
                    Spacer()
                    Button {
                        cleanUp()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                            .padding(12)
                            .background(.white.opacity(0.1), in: Circle())
                    }
                }
                .padding(.horizontal, 24)
                .opacity(isCelebrating ? 0 : 1)

                Spacer()

                // 主能量艙（圓環設計）
                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.08), lineWidth: 16)
                        .frame(width: 220, height: 220)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            LinearGradient(colors: [tint, .white], startPoint: .top, endPoint: .bottom),
                            style: StrokeStyle(lineWidth: 16, lineCap: .round)
                        )
                        .frame(width: 220, height: 220)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: tint.opacity(0.8), radius: 15)
                        .animation(.linear(duration: method == .longPress ? 0.1 : 0.25), value: progress)
                    
                    // 中央圖示與提示
                    VStack(spacing: 8) {
                        Image(systemName: habit.iconName)
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(tint)
                            .scaleEffect(scale)
                        
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                    }
                }
                
                Text(isCelebrating ? "CELEBRATING!" : (method == .longPress ? "請按住螢幕蓄力" : "請連續點擊卡片 3 下"))
                    .font(.headline)
                    .tracking(1.5)
                    .foregroundColor(.white.opacity(0.7))

                Spacer()
                
                // 互動控制區（全螢幕感應玻璃墊）
                if !isCelebrating {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.white.opacity(0.05))
                        .overlay(
                            Text(method == .longPress ? "HOLD" : "TAP TAP TAP")
                                .font(.title3.bold().rounded())
                                .foregroundColor(.white.opacity(0.3))
                        )
                        .frame(height: 120)
                        .padding(.horizontal, 40)
                        .scaleEffect(isInteracting ? 0.96 : 1.0)
                        .animation(.interactiveSpring(), value: isInteracting)
                        .gesture(ritualGesture)
                }
                
                Spacer()
            }
            
            // 慶祝粒子特效疊加層
            if isCelebrating {
                ForEach(0..<25, id: \.self) { i in
                    Circle()
                        .fill(tint.opacity(Double.random(in: 0.6...1.0)))
                        .frame(width: CGFloat.random(in: 6...14))
                        .offset(
                            x: particleAnimation ? CGFloat.random(in: -200...200) : 0,
                            y: particleAnimation ? CGFloat.random(in: -300...300) : 0
                        )
                        .scaleEffect(particleAnimation ? 0 : 1.5)
                        .opacity(particleAnimation ? 0 : 1)
                }
            }
        }
    }

    // 根據設定動態判斷手勢
    private var ritualGesture: some Gesture {
        switch method {
        case .longPress:
            return AnyGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isInteracting {
                            isInteracting = true
                            startLongPressCharging()
                        }
                    }
                    .onEnded { _ in
                        isInteracting = false
                        stopCharging()
                    }
            )
        case .tripleTap:
            return AnyGesture(
                SpatialTapGesture(count: 1)
                    .onEnded { _ in
                        triggerTripleTapProgress()
                    }
            )
        }
    }

    // 長按蓄力邏輯（修復了原本 45% 的斷裂問題）
    private func startLongPressCharging() {
        let feedback = UISelectionFeedbackGenerator()
        feedback.prepare()
        let startedAt = Date.now - (progress * chargeDuration) // 支援斷點續傳

        chargeTask = Task { @MainActor in
            while !Task.isCancelled && isInteracting {
                let current = min(1.0, Date.now.timeIntervalSince(startedAt) / chargeDuration)
                self.progress = current
                onChargeUpdate(current, true)
                
                // 動態微幅縮放產生呼吸感
                withAnimation(.linear(duration: 0.1)) {
                    scale = 1.0 + CGFloat(current * 0.2)
                }
                
                feedback.selectionChanged()
                feedback.prepare()

                if current >= 1.0 {
                    triggerCelebration()
                    return
                }
                try? await Task.sleep(nanoseconds: 60_000_000)
            }
        }
    }

    // 點擊三下累積進度（越按越熱烈）
    private func triggerTripleTapProgress() {
        guard tapCount < 3 else { return }
        tapCount += 1
        isInteracting = true
        
        let feedback = UIImpactFeedbackGenerator(style: tapCount == 1 ? .light : (tapCount == 2 ? .medium : .heavy))
        feedback.impactOccurred()

        // 越按縮放越熱烈
        withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
            scale = 1.0 + CGFloat(tapCount) * 0.15
            progress = Double(tapCount) / 3.0
        }
        
        onChargeUpdate(progress, true)

        if tapCount == 3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                triggerCelebration()
            }
        }
        
        // 如果按太慢，模擬冷卻回彈（防誤觸）
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if tapCount < 3 && isInteracting {
                isInteracting = false
            }
        }
    }

    private func stopCharging() {
        chargeTask?.cancel()
        chargeTask = nil
        if progress < 1.0 {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                progress = 0
                scale = 1.0
            }
            onChargeUpdate(0, false)
        }
    }

    // 聖潔的完成慶祝派對
    private func triggerCelebration() {
        cleanUp()
        isCelebrating = true
        habit.progress = 1.0
        habit.isComplete = true
        onChargeUpdate(1.0, false)
        
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        
        // 瞬間引爆煙火粒子動畫
        withAnimation(.easeOut(duration: 1.5)) {
            particleAnimation = true
        }
        
        // 慶祝 2 秒後，神聖謝幕，全螢幕自動關閉退出
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            dismiss()
        }
    }

    private func cleanUp() {
        chargeTask?.cancel()
        chargeTask = nil
    }
}