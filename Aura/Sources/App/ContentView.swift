import SwiftUI
import SwiftData
import PhotosUI 

/// 儀式完成方式設定
enum CompletionMethod: String, CaseIterable, Identifiable {
    case longPress = "長按蓄力"
    case tripleTap = "連點三下"
    
    var id: String { self.rawValue }
    var iconName: String {
        self == .longPress ? "hand.tap.fill" : "hand.pointer.fill"
    }
}

/// The single composition root for Aura's daily ritual dashboard.
struct ContentView: View {
    @Query(sort: \HabitModel.title) private var habits: [HabitModel]
    @Environment(\.modelContext) private var modelContext
    @State private var isPresentingHabitSheet = false
    
    // 設定完成方式，預設為長按
    @AppStorage("completionMethod") private var completionMethod: CompletionMethod = .longPress
    
    // 全螢幕儀式狀態 management
    @State private var activeRitualHabit: HabitModel? = nil
    
    // 相簿選取器狀態 - 已將類型修正為 UIImage? 以符合 LiquidCanvasView 的型別需求
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var backgroundImage: UIImage? = nil
    @AppStorage("hasCustomBackground") private var hasCustomBackground: Bool = false

    var body: some View {
        // 直接將選取的 UIImage 傳入
        LiquidCanvasView(backgroundImage: backgroundImage) {
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 16) {
                    
                    // 頂部標題與設定按鈕列
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("今天，慢慢完成。")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                            Text("LET THE DAY FILL WITH LIGHT")
                                .font(.caption.weight(.semibold)).tracking(1.8).foregroundStyle(.white.opacity(0.58))
                        }
                        Spacer()
                        
                        // 功能設定按鈕
                        Menu {
                            Picker("完成方式", selection: $completionMethod) {
                                ForEach(CompletionMethod.allCases) { method in
                                    Label(method.rawValue, systemImage: method.iconName)
                                        .tag(method)
                                }
                            }
                            
                            Section("頁面外觀") {
                                PhotosPicker(selection: $selectedItem, matching: .images) {
                                    Label("更換背景照片", systemImage: "photo.on.rectangle")
                                }
                                if hasCustomBackground {
                                    Button(role: .destructive) {
                                        backgroundImage = nil
                                        hasCustomBackground = false
                                        // 清除本地快取
                                        let url = getDocumentsDirectory().appendingPathComponent("custom_bg.png")
                                        try? FileManager.default.removeItem(at: url)
                                    } label: {
                                        Label("恢復預設背景", systemImage: "trash")
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 22))
                                .frame(width: 44, height: 44)
                                .background(.ultraThinMaterial, in: Circle())
                                .overlay(Circle().stroke(.white.opacity(0.15)))
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(.top, 64).padding(.bottom, 8)

                    // 習慣卡片列表
                    ForEach(habits) { habit in
                        HabitCardView(
                            habit: habit,
                            delete: { modelContext.delete(habit) },
                            onTriggerRitual: {
                                activeRitualHabit = habit
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
        .fullScreenCover(item: $activeRitualHabit) { habit in
            RitualCelebrationView(habit: habit, method: completionMethod) { progress, isCharging in
                AuraActivityController.shared.update(habitName: habit.title, progress: progress, neonColorHex: habit.colorHex, isCharging: isCharging)
            }
        }
        // 讀取相簿選取的照片並轉換為 UIImage
        .onChange(of: selectedItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    backgroundImage = uiImage
                    hasCustomBackground = true
                    // 儲存到本地供下次冷啟動載入
                    let url = getDocumentsDirectory().appendingPathComponent("custom_bg.png")
                    try? data.write(to: url)
                }
            }
        }
        // App 打開時自動加載本地沙盒的 UIImage 背景
        .onAppear {
            let url = getDocumentsDirectory().appendingPathComponent("custom_bg.png")
            if let data = try? Data(contentsOf: url), let uiImage = UIImage(data: data) {
                backgroundImage = uiImage
                hasCustomBackground = true
            }
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

#Preview {
    ContentView().modelContainer(SharedContainer.shared)
}