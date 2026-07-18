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
                                    // 2. 點選完成：將當前任務傳入，開啟全螢幕互動艙
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