import SwiftUI

struct FullScreenRitualView: View {
    let habitName: String
    let completionMethod: Int // 0: 點三下, 1: 長按
    let initialProgress: Double
    
    var onComplete: (Double) -> Void // 回傳進度更新 SwiftData
    var onDismiss: () -> Void
    
    @State private var currentProgress: Double = 0.0
    @State private var isCharging = false
    @State private var timer: Timer? = nil
    
    // 互動熱烈度與視覺縮放
    @State private var visualScale: CGFloat = 1.0
    @State private var tapCount = 0
    
    // 步驟 4：原地轉為慶祝畫面狀態
    @State private var isCelebrated = false
    @State private var animateGlow = false

    var body: some View {
        ZStack {
            // 全螢幕純白微光底色
            Color.white.ignoresSafeArea()
                .overlay(
                    // 背後流體粒子熱烈發光，隨著進度變強烈
                    Circle()
                        .fill(RadialGradient(colors: [.blue.opacity(0.3), .purple.opacity(0.4), .clear], center: .center, startRadius: 10, endRadius: 360))
                        .scaleEffect(animateGlow ? 1.8 : 0.9)
                        .opacity(isCelebrated ? 0.9 : (currentProgress * 0.7))
                        .offset(y: -40)
                )
            
            // 頂部關閉按鈕（僅在未完成或慶祝時可點）
            VStack {
                HStack {
                    Spacer()
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.black.opacity(0.2))
                    }
                    .padding(24)
                }
                Spacer()
            }
            
            // 中央核心互動艙
            VStack(spacing: 40) {
                if !isCelebrated {
                    // --- 步驟 3：互動狀態 ---
                    VStack(spacing: 12) {
                        Text(habitName)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(.black)
                        
                        Text(completionMethod == 0 ? "請連點中央能量圈三下" : "請長按中央能量圈充電")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                            .tracking(1)
                    }
                    
                    // 核心巨大互動按鈕
                    ZStack {
                        // 外圈進度
                        Circle()
                            .stroke(Color.black.opacity(0.05), lineWidth: 8)
                            .frame(width: 200, height: 200)
                        
                        Circle()
                            .trim(from: 0, to: currentProgress)
                            .stroke(
                                LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .frame(width: 200, height: 200)
                            .rotationEffect(.degrees(-90))
                        
                        // 內核按鈕
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 170, height: 170)
                            .shadow(color: .black.opacity(0.05), radius: 15)
                            .overlay(
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundColor(isCharging ? .yellow : .black.opacity(0.6))
                            )
                    }
                    .scaleEffect(visualScale)
                    .animation(.spring(response: 0.2, dampingFraction: 0.5), value: visualScale)
                    // 根據設定注入對應的手勢
                    .overlay(
                        Group {
                            if completionMethod == 0 {
                                // 點三下完成手勢
                                Color.clear
                                    .contentShape(Circle())
                                    .onTapGesture { triggerTapImpact() }
                            } else {
                                // 長按充電手勢
                                Color.clear
                                    .contentShape(Circle())
                                    .gesture(
                                        DragGesture(minimumDistance: 0)
                                            .onChanged { _ in if !isCharging { startCharging() } }
                                            .onEnded { _ in endCharging() }
                                    )
                            }
                        }
                    )
                    
                    Text("\(Int(currentProgress * 100))%")
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(.black.opacity(0.4))
                    
                } else {
                    // --- 步驟 4：原地轉為慶祝畫面 ---
                    VStack(spacing: 24) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 110, weight: .black))
                            .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom))
                            .shadow(color: .purple.opacity(0.3), radius: 25)
                            .scaleEffect(visualScale)
                        
                        Text("完美達成")
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .foregroundStyle(.black)
                        
                        Text("今日儀式已注入能量，綻放光芒。")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Button("完成並返回") {
                            onComplete(currentProgress)
                            onDismiss()
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 16)
                        .background(Capsule().fill(.black))
                        .padding(.top, 20)
                    }
                    .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
                }
            }
            .padding(.horizontal, 40)
        }
        .onAppear {
            currentProgress = initialProgress
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                animateGlow = true
            }
        }
    }
    
    // --- 點擊模式邏輯 ---
    private func triggerTapImpact() {
        tapCount += 1
        visualScale = 1.0 + (CGFloat(tapCount) * 0.12)
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred(intensity: CGFloat(tapCount) * 0.33)
        
        withAnimation(.linear(duration: 0.15)) {
            currentProgress = min(Double(tapCount) * 0.34, 1.0)
        }
        
        if currentProgress >= 1.0 {
            triggerCelebration()
        }
    }
    
    // --- 長按模式邏輯 ---
    private func startCharging() {
        isCharging = true
        visualScale = 1.25
        timer = Timer.scheduledTimer(withTimeInterval: 0.04, repeats: true) { _ in
            if currentProgress < 1.0 {
                currentProgress = min(currentProgress + 0.03, 1.0)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                
                if currentProgress >= 1.0 {
                    triggerCelebration()
                }
            }
        }
    }
    
    private func endCharging() {
        isCharging = false
        timer?.invalidate()
        timer = nil
        if currentProgress < 1.0 {
            withAnimation(.spring()) { visualScale = 1.0 }
        }
    }
    
    // 轉入慶祝儀式
    private func triggerCelebration() {
        timer?.invalidate()
        timer = nil
        isCharging = false
        
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) {
            visualScale = 1.0
            isCelebrated = true
        }
    }
}