import SwiftUI
import SwiftData

/// The single composition root for Aura's daily ritual dashboard.
struct ContentView: View {
    @Query(sort: \HabitModel.title) private var habits: [HabitModel]
    @Environment(\.modelContext) private var modelContext
    @State private var isPresentingHabitSheet = false

    var body: some View {
        LiquidCanvasView(backgroundImage: nil) {
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("今天，慢慢完成。")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                        Text("LET THE DAY FILL WITH LIGHT")
                            .font(.caption.weight(.semibold)).tracking(1.8).foregroundStyle(.white.opacity(0.58))
                    }
                    .padding(.top, 64).padding(.bottom, 8)

                    ForEach(habits) { habit in
                        HabitCardView(
                            habitName: habit.title,
                            habitStreak: 0, // 修正：因應 HabitModel 缺少 streak 欄位，先以 0 帶入確保編譯通過
                            habitProgress: habit.progress,
                            delete: { 
                                modelContext.delete(habit) 
                            },
                            onChargeUpdate: { progress, isCharging in
                                // 更新資料庫模型狀態
                                habit.progress = progress
                                
                                // 同步更新即時動態 (Live Activity)
                                AuraActivityController.shared.update(
                                    habitName: habit.title, 
                                    progress: progress, 
                                    neonColorHex: habit.colorHex, 
                                    isCharging: isCharging
                                )
                            }
                        )
                    }

                    if habits.count < 5 {
                        Button { isPresentingHabitSheet = true } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 28, weight: .medium, design: .rounded))
                                .frame(maxWidth: .infinity, minHeight: 94)
                                .foregroundStyle(.white.opacity(0.86))
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 30, style: .continuous).stroke(.cyan.opacity(0.3)))
                                .shadow(color: .cyan.opacity(0.2), radius: 15)
                        }.buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20).padding(.bottom, 40)
            }
        }
        .foregroundStyle(.white)
        .sheet(isPresented: $isPresentingHabitSheet) { CustomHabitSheet() }
    }
}

#Preview {
    ContentView().modelContainer(SharedContainer.shared)
}