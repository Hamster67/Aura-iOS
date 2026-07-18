import SwiftUI
import SwiftData

struct ContentView: View {
    @Query(sort: \HabitModel.title) private var habits: [HabitModel]
    @Environment(\.modelContext) private var modelContext
    @State private var isPresentingHabitSheet = false
    
    // 全局互動設定：0 = 點三下完成, 1 = 長按完成
    @AppStorage("completionMethod") private var completionMethod = 0 
    @State private var showSettings = false
    
    // 全螢幕完成特效狀態
    @State private var activeSuccessHabit: String? = nil
    @State private var showFullSuccess = false

    var body: some View {
        ZStack {
            // 淺色流體背景
            LiquidCanvasView(backgroundImage: nil) {
                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 18) {
                        
                        // 標頭與設定按鈕
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("今天，慢慢完成。")
                                    .font(.system(size: 34, weight: .bold, design: .rounded))
                                Text("LET THE DAY FILL WITH LIGHT")
                                    .font(.caption.weight(.semibold)).tracking(1.8)
                                    .foregroundStyle(.black.opacity(0.4))
                            }
                            Spacer()
                            
                            // 主畫面設定選單按鈕
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
                                completionMethod: completionMethod,
                                delete: {
                                    withAnimation { modelContext.delete(habit) }
                                },
                                onChargeUpdate: { progress, isCharging in
                                    habit.progress = progress
                                    AuraActivityController.shared.update(
                                        habitName: habit.title,
                                        progress: progress,
                                        neonColorHex: habit.colorHex,
                                        isCharging: isCharging
                                    )
                                    
                                    // 觸發全螢幕完成儀式
                                    if progress >= 1.0 && !showFullSuccess {
                                        activeSuccessHabit = habit.title
                                        withAnimation(.easeInOut(duration: 0.5)) {
                                            showFullSuccess = true
                                        }
                                    }
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
            
            // 主畫面底部的設定 Sheet
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
                    .toolbar {
                        Button("完成") { showSettings = false }
                    }
                }
                .presentationDetents([.fraction(0.35)])
            }
            .sheet(isPresented: $isPresentingHabitSheet) { CustomHabitSheet() }
            
            // 全螢幕完成大特效層
            if showFullSuccess, let habitName = activeSuccessHabit {
                FullScreenSuccessView(habitName: habitName) {
                    withAnimation(.easeIn(duration: 0.3)) {
                        showFullSuccess = false
                        activeSuccessHabit = nil
                    }
                }
                .transition(.opacity)
                .zIndex(999)
            }
        }
    }
}

// 全螢幕熱烈完成動畫元件
struct FullScreenSuccessView: View {
    let habitName: String
    var dismiss: () -> Void
    @State private var animateGlow = false
    @State private var scaleEffect = 0.8
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
                .overlay(
                    Circle()
                        .fill(RadialGradient(colors: [.blue.opacity(0.4), .purple.opacity(0.5), .clear], center: .center, startRadius: 10, endRadius: 400))
                        .scaleEffect(animateGlow ? 2.0 : 0.8)
                        .opacity(animateGlow ? 0.8 : 0.3)
                )
            
            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 100, weight: .black))
                    .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom))
                    .scaleEffect(scaleEffect)
                    .shadow(color: .purple.opacity(0.3), radius: 20)
                
                Text(habitName)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                
                Text("已完美達成今日儀式")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .tracking(2)
                
                Button("延續這份光芒") { dismiss() }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(.black))
                    .padding(.top, 40)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.5, blendDuration: 0)) {
                scaleEffect = 1.0
            }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                animateGlow = true
            }
        }
    }
}