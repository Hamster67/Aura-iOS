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
    
    // 自訂視覺狀態
    @AppStorage("ritualBackgroundStyle") private var backgroundStyle = "PureBlack"
    @AppStorage("ritualGlobalTheme") private var globalTheme = "Neon"
    
    // 煙火與動態畫面震動
    @State private var particleAnimation = false
    @State private var dynamicHapticIntensity: CGFloat = 1.0

    private var tint: Color { Color(auraHex: habit.colorHex) }
    private let chargeDuration: TimeInterval = 3.0

    var body: some View {
        ZStack {
            // 背景自訂切換
            Group {
                if backgroundStyle == "Glassmorphism" {
                    Color.clear
                        .background(.ultraThickMaterial)
                } else {
                    Color.black
                }
            }
            .ignoresSafeArea()
            
            // 唯美霓虹光暈（全域風格影響）
            Circle()
                .fill(tint.opacity(globalTheme == "Neon" ? (0.15 + (progress * 0.25)) : 0.05))
                .frame(width: 400, height: 400)
                .blur(radius: 60)
                .offset(y: -50)
                .scaleEffect(isInteracting ? (1.2 + (progress * 0.1)) : 1.0) // 蓄力越久光暈擴散越大
                .animation(.easeInOut(duration: 0.5), value: isInteracting)

            VStack(spacing: 40) {
                // 頂部功能與設定按鈕列
                HStack(spacing: 16) {
                    // 自訂背景與樣式選單
                    Menu {
                        Section("背景樣式") {
                            Button("極致純黑") { backgroundStyle = "PureBlack" }
                            Button("未來感毛玻璃") { backgroundStyle = "Glassmorphism" }
                        }
                        Section("全域主題") {
                            Button("液態霓虹 (Neon)") { globalTheme = "Neon" }
                            Button("極簡單色 (Minimal)") { globalTheme = "Minimal" }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "paintpalette.fill")
                            Text("樣式設定")
                        }
                        .font(.system(.footnote, design: .rounded)).bold()
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.08), in: Capsule())
                    }
                    
                    Spacer()
                    
                    Button {
                        cleanUp()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(width: 36, height: 36)
                            .background(.white.opacity(0.08), in: Circle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
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
                            LinearGradient(colors: [tint, globalTheme == "Neon" ? .white : tint.opacity(0.5)], startPoint: .top, endPoint: .bottom),
                            style: StrokeStyle(lineWidth: 16, lineCap: .round)
                        )
                        .frame(width: 220, height: 220)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: tint.opacity(globalTheme == "Neon" ? 0.8 : 0.2), radius: 15)
                        .animation(.linear(duration: method == .longPress ? 0.1 : 0.25), value: progress)
                    
                    // 中央圖示與進度（強制白色與 Tint 色，防止深色模式污染變成黑字）
                    VStack(spacing: 8) {
                        Image(systemName: habit.iconName)
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(tint)
                            .scaleEffect(scale)
                        
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white) // 強制白色
                    }
                }
                // 震動回饋：按越久畫面產生微幅抖動感
                .offset(x: isInteracting && method == .longPress ? CGFloat.random(in: -progress*3...progress*3) : 0)
                
                Text(isCelebrating ? "CELEBRATING!" : (method == .longPress ? "請按住螢幕蓄力" : "請連續點擊卡片 3 下"))
                    .font(.system(.headline, design: .rounded))
                    .tracking(1.5)
                    .foregroundColor(.white.opacity(0.8)) // 強制白字高透亮

                Spacer()
                
                // 互動控制區（全螢幕感應玻璃墊）
                if !isCelebrating {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.white.opacity(0.06))
                        .overlay(
                            Text(method == .longPress ? "HOLD" : "TAP TAP TAP")
                                .font(.system(.title3, design: .rounded).bold())
                                .foregroundColor(.white.opacity(0.4)) // 強制淡白字
                        )
                        .frame(height: 120)
                        .padding(.horizontal, 40)
                        .scaleEffect(isInteracting ? (0.95 - (progress * 0.03)) : 1.0) // 越久壓得越深
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
                    .map { _ in () }
            )
        case .tripleTap:
            return AnyGesture(
                SpatialTapGesture(count: 1)
                    .onEnded { _ in
                        triggerTripleTapProgress()
                    }
                    .map { _ in () }
            )
        }
    }

    // 長按蓄力邏輯：已修復 85% 暴衝卡頓，確保 0% - 100% 全程絲滑遞增
    private func startLongPressCharging() {
        let feedback = UISelectionFeedbackGenerator()
        feedback.prepare()
        
        // 根據目前進度反推已經過的時間，確保中途放開後能精準續傳
        let alreadyPassedTime = progress * chargeDuration
        let startTime = Date.now - alreadyPassedTime 

        chargeTask = Task { @MainActor in
            while !Task.isCancelled && isInteracting {
                let elapsed = Date.now.timeIntervalSince(startTime)
                let current = min(1.0, elapsed / chargeDuration)
                
                // 1. 精準指派進度，絕不跳格
                self.progress = current
                onChargeUpdate(current, true)
                
                // 2. 動態呼吸與擴張感加劇
                withAnimation(.linear(duration: 0.05)) {
                    scale = 1.0 + CGFloat(current * 0.35)
                }
                
                // 3. 觸覺震動：根據進度線性增強強度與頻率，避免突兀卡頓
                if current < 0.4 {
                    let selectionFeedback = UISelectionFeedbackGenerator()
                    selectionFeedback.selectionChanged()
                } else {
                    // 超過 40% 後，隨進度從 0.4 線性增強震動到 1.0 滿格強度
                    let impactFeedback = UIImpactFeedbackGenerator(style: current > 0.8 ? .heavy : .medium)
                    impactFeedback.impactOccurred(intensity: CGFloat(current))
                }

                if current >= 1.0 {
                    triggerCelebration()
                    return
                }
                
                // 4. 固定高頻率刷新率（約 60 FPS），確保 85% 到 100% 的文字與動畫極致線性
                try? await Task.sleep(nanoseconds: 16_666_667)
            }
        }
    }

    // 連點累積進度（越點震動越強烈）
    private func triggerTripleTapProgress() {
        guard tapCount < 3 else { return }
        tapCount += 1
        isInteracting = true
        
        // 核心：1點輕、2點中、3點重擊，隨次數完美疊加強度
        let hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle = tapCount == 1 ? .light : (tapCount == 2 ? .medium : .heavy)
        let feedback = UIImpactFeedbackGenerator(style: hapticStyle)
        feedback.impactOccurred(intensity: CGFloat(Double(tapCount) / 3.0))

        withAnimation(.spring(response: 0.15, dampingFraction: 0.35)) {
            scale = 1.0 + CGFloat(tapCount) * 0.22 // 每一下都擴得更大
            progress = Double(tapCount) / 3.0
        }
        
        onChargeUpdate(progress, true)

        if tapCount == 3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                triggerCelebration()
            }
        }
        
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

    private func triggerCelebration() {
        cleanUp()
        isCelebrating = true
        
        habit.progress = 1.0
        onChargeUpdate(1.0, false)
        
        // 成功時觸發通知型成功大震動
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        
        withAnimation(.easeOut(duration: 1.5)) {
            particleAnimation = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            dismiss()
        }
    }

    private func cleanUp() {
        chargeTask?.cancel()
        chargeTask = nil
    }
}