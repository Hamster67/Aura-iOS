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
    @State private var isCelebrating = false
    
    // 爆炸漣漪特效控制
    @State private var explosionScale: CGFloat = 1.0
    @State private var explosionOpacity: Double = 0.0
    @State private var hasExploded = false
    
    // 自訂視覺狀態
    @AppStorage("ritualBackgroundStyle") private var backgroundStyle = "PureBlack"
    @AppStorage("ritualGlobalTheme") private var globalTheme = "Neon"
    
    // 煙火粒子
    @State private var particleAnimation = false

    private var tint: Color { Color(auraHex: habit.colorHex) }
    private let chargeDuration: TimeInterval = 3.0

    // 根據進度計算核心縮放：0%->80% 逐漸變大 (1.0->1.35)；80%->100% 快速縮回 (1.35->1.05)
    private var dynamicScale: CGFloat {
        if hasExploded { return 0.0 }
        if progress >= 0.8 {
            let segment = (progress - 0.8) / 0.2 // 0.0 ~ 1.0
            return 1.35 - (segment * 0.30)
        } else {
            return 1.0 + CGFloat(progress * 0.4375)
        }
    }

    var body: some View {
        ZStack {
            // 背景自訂切換
            Group {
                if backgroundStyle == "Glassmorphism" {
                    BlurredBackgroundView(image: nil)
                } else {
                    Color.black
                }
            }
            .ignoresSafeArea()
            
            // 唯美霓虹光暈
            Circle()
                .fill(tint.opacity(globalTheme == "Neon" ? (0.15 + (progress * 0.25)) : 0.05))
                .frame(width: 400, height: 400)
                .blur(radius: 60)
                .offset(y: -50)
                .scaleEffect(isInteracting ? 1.15 : 1.0)
                .animation(.easeInOut(duration: 0.5), value: isInteracting)

            VStack(spacing: 40) {
                // 頂部功能與設定按鈕列
                HStack(spacing: 16) {
                    Menu {
                        Section("背景樣式") {
                            Button("純黑") { backgroundStyle = "PureBlack" }
                            Button("毛玻璃") { backgroundStyle = "Glassmorphism" }
                        }
                        Section("主題") {
                            Button("霓虹 (Neon)") { globalTheme = "Neon" }
                            Button("單色 (Minimal)") { globalTheme = "Minimal" }
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

                // 主能量艙（圓環與爆炸核心）
                ZStack {
                    // 100% 炸開的巨大外擴漣漪
                    Circle()
                        .stroke(tint, lineWidth: 4)
                        .frame(width: 220, height: 220)
                        .scaleEffect(explosionScale)
                        .opacity(explosionOpacity)
                    
                    Circle()
                        .stroke(.white.opacity(0.08), lineWidth: 16)
                        .frame(width: 220, height: 220)
                        .opacity(hasExploded ? 0 : 1)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            LinearGradient(colors: [tint, globalTheme == "Neon" ? .white : tint.opacity(0.5)], startPoint: .top, endPoint: .bottom),
                            style: StrokeStyle(lineWidth: 16, lineCap: .round)
                        )
                        .frame(width: 220, height: 220)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: tint.opacity(globalTheme == "Neon" ? 0.8 : 0.2), radius: 15)
                        .opacity(hasExploded ? 0 : 1)
                    
                    // 中央圖示與進度 (套用移除晃動與 80% 縮回動畫)
                    VStack(spacing: 8) {
                        Image(systemName: habit.iconName)
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(tint)
                        
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .scaleEffect(dynamicScale)
                }
                
                Text(isCelebrating ? "CELEBRATING!" : (method == .longPress ? "請按住螢幕蓄力" : "請連續點擊卡片 3 下"))
                    .font(.system(.headline, design: .rounded))
                    .tracking(1.5)
                    .foregroundColor(.white.opacity(0.8))

                Spacer()
                
                // 互動控制區
                if !isCelebrating {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.white.opacity(0.06))
                        .overlay(
                            Text(method == .longPress ? "HOLD" : "TAP TAP TAP")
                                .font(.system(.title3, design: .rounded).bold())
                                .foregroundColor(.white.opacity(0.4))
                        )
                        .frame(height: 120)
                        .padding(.horizontal, 40)
                        .scaleEffect(isInteracting ? 0.95 : 1.0)
                        .animation(.interactiveSpring(), value: isInteracting)
                        .gesture(ritualGesture)
                }
                
                Spacer()
            }
            
            // 慶祝粒子
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

    // 長按蓄力：已將 Haptic 實例移到外部並預先 prepare，徹底解決 85% 掉幀卡頓問題
    private func startLongPressCharging() {
        let selectionFeedback = UISelectionFeedbackGenerator()
        let mediumFeedback = UIImpactFeedbackGenerator(style: .medium)
        let heavyFeedback = UIImpactFeedbackGenerator(style: .heavy)
        
        selectionFeedback.prepare()
        mediumFeedback.prepare()
        heavyFeedback.prepare()
        
        let alreadyPassedTime = progress * chargeDuration
        let startTime = Date.now - alreadyPassedTime 

        chargeTask = Task { @MainActor in
            while !Task.isCancelled && isInteracting {
                let elapsed = Date.now.timeIntervalSince(startTime)
                let current = min(1.0, elapsed / chargeDuration)
                
                // 使用 linear 讓進度絲滑增加
                withAnimation(.linear(duration: 0.03)) {
                    self.progress = current
                }
                onChargeUpdate(current, true)
                
                // 控制震動頻率與強度，不再重複 init
                if current < 0.4 {
                    selectionFeedback.selectionChanged()
                } else if current < 0.8 {
                    mediumFeedback.impactOccurred(intensity: CGFloat(current))
                } else {
                    heavyFeedback.impactOccurred(intensity: CGFloat(current))
                }

                if current >= 1.0 {
                    SoundManager.playSuccessSound()
                    triggerExplosionEffect()
                    return
                }
                
                try? await Task.sleep(nanoseconds: 30_000_000) // 提高微調休眠時間，減輕 CPU 負擔
            }
        }
    }

    private func triggerTripleTapProgress() {
        guard tapCount < 3 else { return }
        tapCount += 1
        isInteracting = true
        
        SoundManager.playClickSound()
        
        let hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle = tapCount == 1 ? .light : (tapCount == 2 ? .medium : .heavy)
        let feedback = UIImpactFeedbackGenerator(style: hapticStyle)
        feedback.impactOccurred(intensity: CGFloat(Double(tapCount) / 3.0))

        withAnimation(.spring(response: 0.15, dampingFraction: 0.35)) {
            progress = Double(tapCount) / 3.0
        }
        
        onChargeUpdate(progress, true)

        if tapCount == 3 {
            SoundManager.playSuccessSound()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                triggerExplosionEffect()
            }
        }
    }

    private func stopCharging() {
        chargeTask?.cancel()
        chargeTask = nil
        if progress < 1.0 {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                progress = 0
            }
            onChargeUpdate(0, false)
        }
    }

    // 100% 滿格爆炸動畫
    private func triggerExplosionEffect() {
        cleanUp()
        hasExploded = true
        explosionOpacity = 1.0
        
        // 瞬間外擴漣漪炸開
        withAnimation(.easeOut(duration: 0.5)) {
            explosionScale = 3.8
            explosionOpacity = 0.0
        }
        
        // 緊接著開啟粒子大慶祝
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            isCelebrating = true
            habit.progress = 1.0
            onChargeUpdate(1.0, false)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            
            withAnimation(.easeOut(duration: 1.5)) {
                particleAnimation = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            dismiss()
        }
    }

    private func cleanUp() {
        chargeTask?.cancel()
        chargeTask = nil
    }
}