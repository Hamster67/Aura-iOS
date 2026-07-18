import SwiftUI
import SwiftData

struct ContentView: View {
    @Query(sort: \HabitModel.title) private var habits: [HabitModel]
    @Environment(\.modelContext) private var modelContext
    @State private var isPresentingHabitSheet = false
    
    // 全局設定：0 = 點三下完成, 1 = 長按完成
    @AppStorage("completionMethod") private var completionMethod = 0 
    // 背景風格設定：0 = 極光流體, 1 = 深邃宇宙, 2 = 日落微光
    @AppStorage("backgroundStyle") private var backgroundStyle = 0
    @State private var showSettings = false
    
    // 全螢幕互動艙狀態
    @State private var selectedHabitForRitual: HabitModel? = nil

    // 根據設定選擇背景漸層顏色
    var backgroundColors: [Color] {
        switch backgroundStyle {
        case 1: return [.init(red: 0.05, green: 0.05, blue: 0.15), .init(red: 0.2, green: 0.05, blue: 0.3)] // 深邃宇宙
        case 2: return [.init(red: 0.95, green: 0.4, blue: 0.4), .init(red: 0.95, green: 0.7, blue: 0.4)] // 日落微光
        default: return [.init(red: 0.85, green: 0.93, blue: 0.98), .init(red: 0.92, green: 0.88, blue: 0.95)] // 極光流體（預設）
        }
    }
    
    // 字體顏色適配（深色背景用白色，淺色用黑色）
    var textColor: Color {
        backgroundStyle == 1 ? .white : .black
    }

    var body: some View {
        ZStack {
            // 自訂流體背景色
            LinearGradient(colors: backgroundColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
                .overlay(
                    // 這裡與你原本的 LiquidCanvasView 連動，為其注入主題色
                    LiquidCanvasView(backgroundImage: nil) { Color.clear }
                        .opacity(0.6)
                )
            
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 18) {
                    
                    // 標頭與設定
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("今天，慢慢完成。")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundStyle(textColor)
                            Text("LET THE DAY FILL WITH LIGHT")
                                .font(.caption.weight(.semibold)).tracking(1.8)
                                .foregroundStyle(textColor.opacity(0.5))
                        }
                        Spacer()
                        
                        Button { showSettings = true } label: {
                            Image(systemName: "slider.horizontal.3")
                                .font(.title2)
                                .foregroundStyle(textColor.opacity(0.7))
                        }
                    }
                    .padding(.top, 64).padding(.bottom, 8)

                    // 習慣卡片列表
                    ForEach(habits) { habit in
                        HabitCardView(
                            habitName: habit.title,
                            habitStreak: 0,
                            habitProgress: habit.progress,
                            delete: {
                                withAnimation { modelContext.delete(habit) }
                            },
                            triggerRitual: {
                                selectedHabitForRitual = habit
                            }
                        )
                    }

                    if habits.count < 5 {
                        Button { isPresentingHabitSheet = true } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 28, weight: .medium, design: .rounded))
                                .frame(maxWidth: .infinity, minHeight: 94)
                                .foregroundStyle(textColor.opacity(0.5))
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 30, style: .continuous).stroke(textColor.opacity(0.2)))
                        }.buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20).padding(.bottom, 40)
            }
            
            // 全螢幕互動與慶祝艙層
            if let habit = selectedHabitForRitual {
                FullScreenRitualView(
                    habitName: habit.title,
                    completionMethod: completionMethod,
                    initialProgress: habit.progress,
                    themeColors: backgroundColors,
                    onComplete: { finalProgress in
                        habit.progress = finalProgress
                        AuraActivityController.shared.update(
                            habitName: habit.title,
                            progress: finalProgress,
                            neonColorHex: habit.colorHex,
                            isCharging: false
                        )
                    },
                    onDismiss: {
                        selectedHabitForRitual = nil
                    }
                )
                .transition(.opacity)
                .zIndex(999)
            }
        }
        // 控制中心設定選單
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                Form {
                    Section("自訂環境氛圍 (Aura)") {
                        Picker("背景風格", selection: $backgroundStyle) {
                            Text("✨ 極光流體 (淺色極簡)").tag(0)
                            Text("🌌 深邃宇宙 (暗黑沉浸)").tag(1)
                            Text("🌅 日落微光 (溫暖和煦)").tag(2)
                        }
                        .pickerStyle(.inline)
                    }
                    
                    Section("自訂完成互動方式") {
                        Picker("互動模式", selection: $completionMethod) {
                            Text("連點三下完成（越點越熱烈）").tag(0)
                            Text("長按按鈕完成（越按越熱烈）").tag(1)
                        }
                        .pickerStyle(.inline)
                    }
                }
                .navigationTitle("Aura 儀式設定")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { Button("儲存") { showSettings = false } }
            }
            .presentationDetents([.fraction(0.55)])
        }
        .sheet(isPresented: $isPresentingHabitSheet) { CustomHabitSheet() }
    }
}

// ==========================================
// MARK: - 粒子爆炸特效元件 (ParticleEmitter)
// ==========================================
struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGSize
    var scale: CGFloat
    var opacity: Double
    var color: Color
}

struct ParticleBurstView: View {
    @Binding var trigger: Bool
    var burstColor: Color = .purple
    @State private var particles: [Particle] = []
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                for particle in particles {
                    context.opacity = particle.opacity
                    let rect = CGRect(
                        x: particle.position.x - (10 * particle.scale) / 2,
                        y: particle.position.y - (10 * particle.scale) / 2,
                        width: 10 * particle.scale,
                        height: 10 * particle.scale
                    )
                    // 繪製圓形發光星芒粒子
                    context.fill(Path(ellipseIn: rect), with: .color(particle.color))
                }
            }
            .onChange(of: timeline.date) { _ in
                updateParticles()
            }
        }
        .onChange(of: trigger) { newValue in
            if newValue { spawnParticles() }
        }
    }
    
    private func spawnParticles() {
        var newParticles: [Particle] = []
        let colors: [Color] = [burstColor, .blue, .cyan, .white, .orange]
        
        // 瞬間產生 40 個向四周噴發的星芒粒子
        for _ in 0..<40 {
            let angle = Double.random(in: 0...(2 * .pi))
            let speed = Double.random(in: 4...12)
            let velocity = CGSize(width: cos(angle) * speed, height: sin(angle) * speed)
            
            newParticles.append(Particle(
                position: CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2 - 40),
                velocity: velocity,
                scale: CGFloat.random(in: 0.5...1.5),
                opacity: 1.0,
                color: colors.randomElement() ?? .purple
            ))
        }
        self.particles = newParticles
    }
    
    private func updateParticles() {
        for i in 0..<particles.count {
            particles[i].position.x += particles[i].velocity.width
            particles[i].position.y += particles[i].velocity.height
            // 模擬微小的阻力與重力下墜
            particles[i].velocity.height += 0.15 
            particles[i].opacity -= 0.02
            particles[i].scale *= 0.98
        }
        // 移除看不見的粒子
        particles.removeAll { $0.opacity <= 0 }
    }
}

// ==========================================
// MARK: - 降維打擊版：強佔最高手勢優先權 (FullScreenRitualView)
// ==========================================
struct FullScreenRitualView: View {
    let habitName: String
    let completionMethod: Int
    let initialProgress: Double
    let themeColors: [Color] 
    
    var onComplete: (Double) -> Void
    var onDismiss: () -> Void
    
    @State private var currentProgress: Double = 0.0
    @State private var isCharging = false
    @State private var timer: Timer? = nil
    
    @State private var visualScale: CGFloat = 1.0
    @State private var tapCount = 0 
    
    @State private var isCelebrated = false
    @State private var animateGlow = false
    @State private var triggerParticleBurst = false

    var body: some View {
        ZStack {
            // 1. 背景層
            LinearGradient(colors: themeColors, startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
                .overlay(
                    Circle()
                        .fill(RadialGradient(colors: [(themeColors.first ?? .blue).opacity(0.5), .purple.opacity(0.3), .clear], center: .center, startRadius: 10, endRadius: 360))
                        .scaleEffect(animateGlow ? 1.6 : 0.9)
                        .opacity(isCelebrated ? 0.9 : (currentProgress * 0.7))
                        .offset(y: -40)
                )
            
            // 2. 粒子特效層
            ParticleBurstView(trigger: $triggerParticleBurst, burstColor: themeColors.first ?? .purple)
                .zIndex(5)
            
            // 3. 主要內容互動層
            VStack(spacing: 40) {
                if !isCelebrated {
                    VStack(spacing: 12) {
                        Text(habitName)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(.black)
                        
                        Text(completionMethod == 0 ? "請連點中央能量圈三下" : "請長按中央能量圈充電")
                            .font(.subheadline)
                            .foregroundStyle(.black.opacity(0.5))
                            .tracking(1)
                    }
                    .padding(.top, 60)
                    
                    // 中央能量圈主體
                    ZStack {
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
                        
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 170, height: 170)
                            .shadow(color: .black.opacity(0.05), radius: 15)
                            .overlay(
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundColor(isCharging ? .yellow : .black.opacity(0.6))
                            )
                        
                        // 【終極關鍵】：放一個真正著色的實體圓形覆蓋在最上面，並直接綁定最高優先權手勢
                        Circle()
                            .fill(Color.white.opacity(0.01))
                            .frame(width: 200, height: 200)
                            // 這裡強行用 highPriorityGesture 覆蓋掉外面所有 LiquidCanvas 或 ScrollView 的干擾
                            .highPriorityGesture(
                                Group {
                                    if completionMethod == 0 {
                                        // 連點模式：用普通點擊
                                        TapGesture()
                                            .onEnded {
                                                triggerTapImpact()
                                            }
                                    } else {
                                        // 長按模式：用模擬長按的 DragGesture
                                        DragGesture(minimumDistance: 0)
                                            .onChanged { _ in
                                                if !isCharging { startCharging() }
                                            }
                                            .onEnded { _ in
                                                endCharging()
                                            }
                                    }
                                }
                            )
                    }
                    .frame(width: 200, height: 200)
                    .scaleEffect(visualScale)
                    .animation(.spring(response: 0.2, dampingFraction: 0.5), value: visualScale)
                    
                    Text("\(Int(currentProgress * 100))%")
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(.black.opacity(0.4))
                    
                } else {
                    // 慶祝完成畫面
                    VStack(spacing: 24) {
                        Spacer()
                        
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
                            .foregroundColor(.black.opacity(0.6))
                        
                        Button(action: {
                            onComplete(currentProgress)
                            onDismiss()
                        }) {
                            Text("完成並返回")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 40)
                                .padding(.vertical, 16)
                                .background(Capsule().fill(.black))
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 20)
                        
                        Spacer()
                    }
                    .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
                }
            }
            .padding(.horizontal, 40)
            
            // 右上角關閉按鈕
            if !isCelebrated {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            onDismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 30))
                                .foregroundStyle(.black.opacity(0.3))
                                .padding(24)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                }
                .zIndex(10)
            }
        }
        .onAppear {
            currentProgress = initialProgress
            tapCount = Int(round(initialProgress / 0.34))
            
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                animateGlow = true
            }
        }
    }
    
    private func triggerTapImpact() {
        tapCount += 1
        visualScale = 1.0 + (CGFloat(tapCount) * 0.08)
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred(intensity: min(CGFloat(tapCount) * 0.33, 1.0))
        
        withAnimation(.spring(response: 0.15, dampingFraction: 0.6)) {
            currentProgress = min(Double(tapCount) * 0.34, 1.0)
        }
        
        if currentProgress >= 1.0 {
            triggerCelebration()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if !isCelebrated {
                    withAnimation(.spring()) { visualScale = 1.0 }
                }
            }
        }
    }
    
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
    
    private func triggerCelebration() {
        timer?.invalidate()
        timer = nil
        isCharging = false
        
        triggerParticleBurst = true
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) {
            visualScale = 1.0
            isCelebrated = true
        }
    }
}
// ==========================================
// MARK: - 自動生成專用：Aura 療癒系圖示
// ==========================================
struct AuraAppIconView: View {
    var body: some View {
        ZStack {
            // 1. 深色底：像夜裡安靜的水面
            Color(red: 0.05, green: 0.06, blue: 0.12)
            
            // 2. 底層的霓虹光暈（擴散的能量）
            Circle()
                .fill(RadialGradient(
                    colors: [.init(red: 0.0, green: 0.8, blue: 1.0).opacity(0.6), .clear],
                    center: .center, startRadius: 50, endRadius: 850
                ))
                .offset(x: -120, y: -120)
            
            Circle()
                .fill(RadialGradient(
                    colors: [.init(red: 0.9, green: 0.3, blue: 0.9).opacity(0.5), .clear],
                    center: .center, startRadius: 50, endRadius: 800
                ))
                .offset(x: 150, y: 180)

            // 3. 核心：一滴玻璃水珠 (Liquid Glass)
            ZStack {
                // 水珠主體與折射
                Circle()
                    .fill(.white.opacity(0.07))
                    .background(
                        Circle()
                            .fill(LinearGradient(
                                colors: [.white.opacity(0.25), .clear, .init(red: 0.0, green: 0.8, blue: 1.0).opacity(0.25)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ))
                    )
                
                // 水珠邊緣的高光
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.65), .white.opacity(0.1), .init(red: 0.0, green: 0.8, blue: 1.0).opacity(0.4)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: 8
                    )
                
                // 頂部核心反光（被光喚醒的瞬間）
                Ellipse()
                    .fill(.white.opacity(0.6))
                    .frame(width: 160, height: 90)
                    .rotationEffect(.degrees(-30))
                    .offset(x: -120, y: -150)
                    .blur(radius: 2)
                
                // 底部環境折射光
                Circle()
                    .fill(Color(red: 0.8, green: 0.3, blue: 0.9).opacity(0.45))
                    .frame(width: 220, height: 220)
                    .offset(x: 90, y: 120)
                    .blur(radius: 40)
            }
            .frame(width: 600, height: 600)
            .shadow(color: .black.opacity(0.6), radius: 60, x: 0, y: 40)
        }
        .frame(width: 1024, height: 1024) // 嚴格符合 App Store 1024x1024 規格
    }
}