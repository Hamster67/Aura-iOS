import SwiftUI
import SwiftData

struct ContentView: View {
    @Query(sort: \HabitModel.title) private var habits: [HabitModel]
    @Environment(\.modelContext) private var modelContext
    @State private var isPresentingHabitSheet = false
    
    // 全局互動設定：0 = 點三下完成, 1 = 長按完成
    @AppStorage("completionMethod") private var completionMethod = 0 
    @State private var showSettings = false
    
    // 全螢幕互動艙狀態
    @State private var selectedHabitForRitual: HabitModel? = nil

    var body: some View {
        ZStack {
            // 淺色流體背景
            LiquidCanvasView(backgroundImage: nil) {
                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 18) {
                        
                        // 標頭與設定
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("今天，慢慢完成。")
                                    .font(.system(size: 34, weight: .bold, design: .rounded))
                                Text("LET THE DAY FILL WITH LIGHT")
                                    .font(.caption.weight(.semibold)).tracking(1.8)
                                    .foregroundStyle(.black.opacity(0.4))
                            }
                            Spacer()
                            
                            Button { showSettings = true } label: {
                                Image(systemName: "gearshape.fill")
                                    .font(.title2)
                                    .foregroundStyle(.black.opacity(0.6))
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
                                    // 點選完成：將當前任務傳入，開啟全螢幕互動艙
                                    selectedHabitForRitual = habit
                                }
                            )
                        }

                        if habits.count < 5 {
                            Button { isPresentingHabitSheet = true } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 28, weight: .medium, design: .rounded))
                                    .frame(maxWidth: .infinity, minHeight: 94)
                                    .foregroundStyle(.black.opacity(0.5))
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
                                    .overlay(RoundedRectangle(cornerRadius: 30, style: .continuous).stroke(.white.opacity(0.6)))
                            }.buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20).padding(.bottom, 40)
                }
            }
            .foregroundStyle(.black)
            
            // 全螢幕互動與慶祝艙層
            if let habit = selectedHabitForRitual {
                FullScreenRitualView(
                    habitName: habit.title,
                    completionMethod: completionMethod,
                    initialProgress: habit.progress,
                    onComplete: { finalProgress in
                        // 更新 SwiftData
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
        // 設定選單
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                Form {
                    Section("自訂完成互動方式") {
                        Picker("互動模式", selection: $completionMethod) {
                            Text("連點三下完成（越點越熱烈）").tag(0)
                            Text("長按按鈕完成（越按越熱烈）").tag(1)
                        }
                        .pickerStyle(.inline)
                    }
                }
                .navigationTitle("Aura 設定")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { Button("完成") { showSettings = false } }
            }
            .presentationDetents([.fraction(0.35)])
        }
        .sheet(isPresented: $isPresentingHabitSheet) { CustomHabitSheet() }
    }
}

// ==========================================
// MARK: - 全螢幕互動艙與原地慶祝畫面 (FullScreenRitualView)
// ==========================================
struct FullScreenRitualView: View {
    let habitName: String
    let completionMethod: Int // 0: 點三下, 1: 長按
    let initialProgress: Double
    
    var onComplete: (Double) -> Void
    var onDismiss: () -> Void
    
    @State private var currentProgress: Double = 0.0
    @State private var isCharging = false
    @State private var timer: Timer? = nil
    
    @State private var visualScale: CGFloat = 1.0
    @State private var tapCount = 0
    
    @State private var isCelebrated = false
    @State private var animateGlow = false

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
                .overlay(
                    Circle()
                        .fill(RadialGradient(colors: [.blue.opacity(0.3), .purple.opacity(0.4), .clear], center: .center, startRadius: 10, endRadius: 360))
                        .scaleEffect(animateGlow ? 1.8 : 0.9)
                        .opacity(isCelebrated ? 0.9 : (currentProgress * 0.7))
                        .offset(y: -40)
                )
            
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
            
            VStack(spacing: 40) {
                if !isCelebrated {
                    VStack(spacing: 12) {
                        Text(habitName)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(.black)
                        
                        Text(completionMethod == 0 ? "請連點中央能量圈三下" : "請長按中央能量圈充電")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                            .tracking(1)
                    }
                    
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
                    }
                    .scaleEffect(visualScale)
                    .animation(.spring(response: 0.2, dampingFraction: 0.5), value: visualScale)
                    .overlay(
                        Group {
                            if completionMethod == 0 {
                                Color.clear
                                    .contentShape(Circle())
                                    .onTapGesture { triggerTapImpact() }
                            } else {
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
        
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) {
            visualScale = 1.0
            isCelebrated = true
        }
    }
}