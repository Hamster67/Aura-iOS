import SwiftUI
import SwiftData

struct HabitCardView: View {
    let habit: HabitModel
    let delete: () -> Void
    let onTriggerRitual: () -> Void
    
    @State private var isEditing = false
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        HStack {
            // 左側與中間：點擊此區域才會觸發充能儀式
            Button {
                SoundManager.shared.triggerLightImpact()
                SoundManager.shared.playChargingSound()
                
                onTriggerRitual()
                
                if habit.progress >= 1.0 {
                    SoundManager.shared.triggerSuccessNotification()
                    SoundManager.shared.playCompletionSound()
                }
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: habit.iconName)
                        .font(.system(size: 20))
                        .foregroundStyle(Color(auraHex: habit.colorHex)) // 💡 使用專案內建的 auraHex
                        .frame(width: 44, height: 44)
                        .background(Color(auraHex: habit.colorHex).opacity(0.12), in: Circle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(habit.title)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(habit.isPaused ? .white.opacity(0.4) : .white)
                            
                            // 暫停或略過狀態標籤
                            if habit.isPaused {
                                Text("已暫停")
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.orange.opacity(0.2))
                                    .foregroundStyle(.orange)
                                    .clipShape(Capsule())
                            } else if !habit.isRequiredToday {
                                Text("已排解")
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.white.opacity(0.1))
                                    .foregroundStyle(.white.opacity(0.4))
                                    .clipShape(Capsule())
                            }
                        }
                        
                        HStack(spacing: 12) {
                            Text("進度：\(Int(habit.progress * 100))%")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.white.opacity(0.4))
                            
                            if habit.streakCount > 0 {
                                Label("\(habit.streakCount) 連勝", systemImage: "flame.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .contentShape(Rectangle()) 
            }
            .buttonStyle(.plain)
            .disabled(habit.isPaused)
            
            // 右側：獨立的操作選單
            Menu {
                Button {
                    isEditing = true
                } label: {
                    Label("編輯任務", systemImage: "pencil")
                }
                
                Button(role: .destructive) {
                    withAnimation { delete() }
                } label: {
                    Label("刪除任務", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.05), in: Circle())
            }
        }
        .padding(.all, 20)
        .background(.white.opacity(0.02))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
        .sheet(isPresented: $isEditing) {
            EditHabitSheet(habit: habit)
        }
    }
}

struct EditHabitSheet: View {
    @Bindable var habit: HabitModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    // 💡 保持乾淨的 6 碼 Hex 格式
    let neonColors = ["00F2FE", "F355DA", "FF5E62", "1ADF66", "FFD200"]
    let allSymbols = [
        "bolt.shield", "sparkles", "brain.headlight", "heart.text.square", "moon.stars", "flame", "drop.fill", "sun.max",
        "figure.mind.and.body", "figure.walk", "figure.run", "heart.fill", "pills", "bed.double.fill", "lungs.fill",
        "book.closed", "doc.text", "laptopcomputer", "terminal", "pencil.and.outline", "graduationcap", "briefcase",
        "cup.and.saucer", "fork.knife", "wineglass", "hourglass", "timer", "alarm", "bell", "calendar",
        "leaf", "tree", "wind", "guitars", "music.note", "house", "infinity", "scope", "eye"
    ]
    
    var filteredSymbols: [String] {
        if searchText.isEmpty { return allSymbols }
        else { return allSymbols.filter { $0.lowercased().contains(searchText.lowercased()) } }
    }
    
    let columns = [GridItem(.adaptive(minimum: 50))]

    var body: some View {
        NavigationStack {
            ZStack {
                // 這裡使用我們自訂的安全色彩解析器
                LinearGradient(
                    colors: [Color.fromHex("0B0D17").opacity(0.85), Color.fromHex("16192B").opacity(0.85)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        Capsule()
                            .fill(.white.opacity(0.15))
                            .frame(width: 40, height: 4)
                            .padding(.top, 12)
                        
                        Text("更改任務")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)
                        
                        // 1. 意圖名稱輸入框
                        VStack(alignment: .leading, spacing: 12) {
                            Text("任務名稱")
                                .font(.system(size: 12, weight: .semibold)).tracking(1.2)
                                .foregroundStyle(.white.opacity(0.4))
                            
                            TextField("輸入名稱...", text: $habit.title)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.white)
                                .tint(Color.fromHex(habit.colorHex))
                        }
                        .padding(.all, 20)
                        .background(.white.opacity(0.03))
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color.fromHex(habit.colorHex).opacity(0.2), lineWidth: 1)
                        )
                        .padding(.horizontal, 24)
                        
                        // 2. 提醒機制與防禦狀態管理設定
                        VStack(alignment: .leading, spacing: 12) {
                            Text("提醒機制與狀態管理")
                                .font(.system(size: 12, weight: .semibold)).tracking(1.2)
                                .foregroundStyle(.white.opacity(0.4))
                            
                            VStack(spacing: 14) {
                                Picker("週期", selection: $habit.recurrenceType) {
                                    ForEach(RecurrenceType.allCases, id: \.self) { type in
                                        Text(type.rawValue).tag(type)
                                    }
                                }
                                .pickerStyle(.segmented)
                                
                                if habit.recurrenceType == .customYears {
                                    HStack {
                                        Text("每隔幾年提醒：")
                                            .font(.system(size: 14))
                                            .foregroundStyle(.white.opacity(0.7))
                                        Spacer()
                                        Stepper("\(habit.customIntervalYears) 年", value: $habit.customIntervalYears, in: 2...10)
                                            .foregroundColor(.white)
                                    }
                                    .padding(.top, 4)
                                }
                                
                                if habit.recurrenceType != .daily {
                                    DatePicker(
                                        habit.recurrenceType == .monthly ? "每月提醒日" : "目標指定日期",
                                        selection: $habit.targetDate,
                                        displayedComponents: .date
                                    )
                                    .environment(\.colorScheme, .dark)
                                    .font(.system(size: 14))
                                    .foregroundStyle(.white.opacity(0.7))
                                }
                                
                                Divider().background(.white.opacity(0.1))
                                
                                HStack(spacing: 16) {
                                    Button(role: habit.isPaused ? .none : .destructive) {
                                        withAnimation { habit.togglePause() }
                                    } label: {
                                        Label(habit.isPaused ? "恢復提醒" : "暫停提醒", systemImage: habit.isPaused ? "play.fill" : "pause.fill")
                                            .font(.system(size: 14, weight: .medium))
                                            .frame(maxWidth: .infinity, minHeight: 40)
                                            .background(habit.isPaused ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                    
                                    Button {
                                        withAnimation { habit.skipCurrentPeriod() }
                                        dismiss()
                                    } label: {
                                        Label("略過今天", systemImage: "forward.fill")
                                            .font(.system(size: 14, weight: .medium))
                                            .frame(maxWidth: .infinity, minHeight: 40)
                                            .background(Color.white.opacity(0.1))
                                            .foregroundColor(.white)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                    .disabled(!habit.isRequiredToday)
                                    .opacity(habit.isRequiredToday ? 1.0 : 0.4)
                                }
                            }
                            .padding(.all, 16)
                            .background(.white.opacity(0.03))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(.horizontal, 24)
                        
                        // 3. 顏色調整 (💡 已改用確保能出顏色的 Color.fromHex)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("調整色彩")
                                .font(.system(size: 12, weight: .semibold)).tracking(1.2)
                                .foregroundStyle(.white.opacity(0.4))
                            
                            HStack(spacing: 18) {
                                ForEach(neonColors, id: \.self) { hex in
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                            habit.colorHex = hex
                                        }
                                    } label: {
                                        Circle()
                                            .fill(Color.fromHex(hex))
                                            .frame(width: 36, height: 36)
                                            .overlay(
                                                Circle()
                                                    .stroke(.white, lineWidth: habit.colorHex.replacingOccurrences(of: "#", with: "") == hex ? 2 : 0)
                                                    .scaleEffect(habit.colorHex.replacingOccurrences(of: "#", with: "") == hex ? 1.15 : 1.0)
                                            )
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        
                        // 4. 圖示搜尋與滾動選擇區
                        VStack(alignment: .leading, spacing: 12) {
                            Text("變更標誌")
                                .font(.system(size: 12, weight: .semibold)).tracking(1.2)
                                .foregroundStyle(.white.opacity(0.4))
                            
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(.white.opacity(0.3))
                                TextField("搜尋圖示...", text: $searchText)
                                    .font(.system(size: 14))
                                    .foregroundStyle(.white)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 14)
                            .background(.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            ScrollView {
                                LazyVGrid(columns: columns, spacing: 14) {
                                    ForEach(filteredSymbols, id: \.self) { icon in
                                        Button {
                                            habit.iconName = icon
                                        } label: {
                                            Image(systemName: icon)
                                                .font(.system(size: 20))
                                                .foregroundStyle(habit.iconName == icon ? Color.fromHex(habit.colorHex) : .white.opacity(0.4))
                                                .frame(width: 46, height: 46)
                                                .background(habit.iconName == icon ? Color.fromHex(habit.colorHex).opacity(0.15) : Color.white.opacity(0.04))
                                                .clipShape(Circle())
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.fromHex(habit.colorHex).opacity(habit.iconName == icon ? 0.5 : 0), lineWidth: 1)
                                                )
                                        }
                                    }
                                }
                                .padding(.vertical, 6)
                            }
                            .frame(maxHeight: 180)
                        }
                        .padding(.horizontal, 24)
                        
                        Spacer()
                        
                        Button {
                            dismiss()
                        } label: {
                            Text("儲存變更")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity, minHeight: 56)
                                .background(Color.fromHex(habit.colorHex))
                                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
        .presentationBackground(.clear)
    }
}

// 💡 專屬的安全色彩擴充功能，避開專案原初始化器的任何潛在干擾
fileprivate extension Color {
    static func fromHex(_ hexStr: String) -> Color {
        var cleanHex = hexStr.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cleanHex.hasPrefix("#") {
            cleanHex.remove(at: cleanHex.startIndex)
        }
        
        // 確保長度正確
        if cleanHex.count != 6 {
            return Color.gray // Fallback 預設安全色
        }
        
        var rgbValue: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&rgbValue)
        
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        
        return Color(red: r, green: g, blue: b)
    }
}