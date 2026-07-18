import SwiftUI
import SwiftData
import PhotosUI 

enum CompletionMethod: String, CaseIterable, Identifiable {
    case longPress = "長按蓄力"
    case tripleTap = "連點三下"
    var id: String { self.rawValue }
    var iconName: String { self == .longPress ? "hand.tap.fill" : "hand.pointer.fill" }
}

struct ContentView: View {
    @Query(sort: \HabitModel.title) private var habits: [HabitModel]
    @Environment(\.modelContext) private var modelContext
    @State private var isPresentingHabitSheet = false
    @AppStorage("completionMethod") private var completionMethod: CompletionMethod = .longPress
    @State private var activeRitualHabit: HabitModel? = nil
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var isShowingPhotoPicker = false
    @State private var backgroundImage: UIImage? = nil
    @AppStorage("hasCustomBackground") private var hasCustomBackground: Bool = false

    // ⏳ 3秒全螢幕動畫與訊息管理
    @State private var overlayMessage: String? = nil
    @State private var showOverlay = false
    @State private var overlayTimer: Timer? = nil

    var body: some View {
        LiquidCanvasView(backgroundImage: backgroundImage) {
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 16) {
                    
                    // 頂部標題與設定列
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("今天，慢慢完成。")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                            Text("LET THE DAY FILL WITH LIGHT")
                                .font(.caption.weight(.semibold)).tracking(1.8).foregroundStyle(.white.opacity(0.58))
                        }
                        Spacer()
                        
                        Menu {
                            Picker("完成方式", selection: $completionMethod) {
                                ForEach(CompletionMethod.allCases) { method in
                                    Label(method.rawValue, systemImage: method.iconName).tag(method)
                                }
                            }
                            
                            Section("頁面外觀") {
                                Button { isShowingPhotoPicker = true } label: {
                                    Label("更換背景照片", systemImage: "photo.on.rectangle")
                                }
                                if hasCustomBackground {
                                    Button(role: .destructive) {
                                        backgroundImage = nil
                                        hasCustomBackground = false
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

                    // 🔥 連勝統計總覽面板
                    if !habits.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 12) {
                                Image(systemName: "flame.fill")
                                    .font(.title2)
                                    .foregroundStyle(.linearGradient(colors: [.orange, .pink], startPoint: .top, endPoint: .bottom))
                                
                                let totalStreaks = habits.map { $0.streakCount }.max() ?? 0
                                Text("當前最高連勝：\(totalStreaks) 天")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                            }
                            
                            // 快捷調度管理選單
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(habits) { habit in
                                        Menu {
                                            if habit.isPaused {
                                                Button("恢復打卡") { habit.isPaused = false }
                                            } else {
                                                Button("無限期暫停") {
                                                    habit.isPaused = true
                                                    triggerOverlay(message: "「\(habit.title)」已暫停\n正在進入休眠儀式...")
                                                }
                                                Button("略過 1 天") {
                                                    habit.skipUntilDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
                                                    triggerOverlay(message: "已略過「\(habit.title)」本日打卡\n維持能量流動中...")
                                                }
                                                Button("略過 3 天") {
                                                    habit.skipUntilDate = Calendar.current.date(byAdding: .day, value: 3, to: Date())
                                                    triggerOverlay(message: "已為「\(habit.title)」請假 3 天\n好好調整呼吸...")
                                                }
                                            }
                                            if habit.skipUntilDate != nil {
                                                Button("🔄 取消略過") { habit.skipUntilDate = nil }
                                            }
                                        } label: {
                                            HStack(spacing: 4) {
                                                Text(habit.title)
                                                Image(systemName: habit.isPaused ? "pause.fill" : (habit.skipUntilDate != nil ? "forward.fill" : "checkmark.shield"))
                                            }
                                            .font(.caption.weight(.medium))
                                            .padding(.horizontal, 12).padding(.vertical, 6)
                                            .background(.white.opacity(0.1), in: Capsule())
                                            .foregroundStyle(habit.isPaused ? .yellow : .white)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
                        .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.08)))
                    }

                    // 習慣卡片列表
                    ForEach(habits) { habit in
                        HabitCardView(
                            habit: habit,
                            delete: { modelContext.delete(habit) },
                            onTriggerRitual: { activeRitualHabit = habit } // 點擊卡片直接進入打卡充能
                        )
                        // iOS 17 新版無參數 onChange 語法，避免 Deprecated 警告
                        .onChange(of: habit.progress) {
                            if habit.isComplete && habit.lastCheckInDate?.timeIntervalSinceNow ?? -99999 < -10 {
                                habit.checkIn()
                            }
                        }
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
            
            // 🔒 3秒強制的極簡全螢幕鎖定退出層
            if showOverlay, let message = overlayMessage {
                ZStack {
                    Color.black.opacity(0.96)
                        .ignoresSafeArea()
                        .blur(radius: 10)
                    
                    VStack(spacing: 24) {
                        ProgressView()
                            .tint(.cyan)
                            .scaleEffect(1.6)
                        
                        Text(message)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 40)
                    }
                    .scaleEffect(showOverlay ? 1.0 : 0.92)
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.92)),
                    removal: .opacity.combined(with: .scale(scale: 1.05))
                ))
            }
        }
        .foregroundStyle(.white)
        .photosPicker(isPresented: $isShowingPhotoPicker, selection: $selectedItem, matching: .images)
        .sheet(isPresented: $isPresentingHabitSheet) { CustomHabitSheet() }
        .fullScreenCover(item: $activeRitualHabit) { habit in
            RitualCelebrationView(habit: habit, method: completionMethod) { progress, isCharging in
                AuraActivityController.shared.update(habitName: habit.title, progress: progress, neonColorHex: habit.colorHex, isCharging: isCharging) //
            }
        }
        // iOS 17 新版無參數 onChange 語法
        .onChange(of: selectedItem) {
            Task {
                if let data = try? await selectedItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    backgroundImage = uiImage
                    hasCustomBackground = true
                    let url = getDocumentsDirectory().appendingPathComponent("custom_bg.png")
                    try? data.write(to: url)
                }
            }
        }
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
    
    private func triggerOverlay(message: String) {
        overlayTimer?.invalidate()
        overlayMessage = message
    
        withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
            showOverlay = true
        }
    
        overlayTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            withAnimation(.curveEaseInDuration(0.3)) {
                showOverlay = false
            }
        }
    }
}

// MARK: - 動態曲線擴充
extension Animation {
    static func curveEaseInDuration(_ duration: TimeInterval) -> Animation {
        return .timingCurve(0.42, 0, 1, 1, duration: duration)
    }
}