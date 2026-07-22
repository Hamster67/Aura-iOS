import SwiftUI
import SwiftData

struct CustomHabitSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    // 💡 統一格式：預設值去掉 #，與 neonColors 保持一致
    @State private var selectedColorHex = "00F2FE" 
    @State private var selectedIcon = "bolt.shield"
    
    @State private var selectedRecurrence: RecurrenceType = .daily
    @State private var customIntervalYears = 4
    @State private var targetDate = Date()
    
    @State private var searchText = ""
    let columns = [GridItem(.adaptive(minimum: 50))]
    
    // 💡 乾淨的 6 碼 Hex 格式
    let neonColors = ["00F2FE", "F355DA", "FF5E62", "1ADF66", "FFD200"]
    
    // 💡 已修正：第三個圖示更新為正確支援的 brain.headsparks
    let icons = [
        "bolt.shield", "sparkles", "brain.headsparks", "heart.text.square", "moon.stars", "flame", "drop.fill", "sun.max",
        "figure.mind.and.body", "figure.walk", "figure.run", "heart.fill", "pills", "bed.double.fill", "lungs.fill",
        "book.closed", "doc.text", "laptopcomputer", "terminal", "pencil.and.outline", "graduationcap", "briefcase",
        "cup.and.saucer", "fork.knife", "wineglass", "hourglass", "timer", "alarm", "bell", "calendar",
        "leaf", "tree", "wind", "guitars", "music.note", "house", "infinity", "scope", "eye"
    ]
    
    var filteredSymbols: [String] {
        if searchText.isEmpty {
            return icons
        } else {
            return icons.filter { $0.lowercased().contains(searchText.lowercased()) }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // 深色漸層背景 + 毛玻璃底層
                LinearGradient(
                    colors: [Color.fromCustomHex("0B0D17").opacity(0.85), Color.fromCustomHex("16192B").opacity(0.85)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        Capsule()
                            .fill(.white.opacity(0.15))
                            .frame(width: 40, height: 4)
                            .padding(.top, 12)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("創建新的任務")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Text("為你的日常更注入能量！")
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        
                        // 1. 任務名稱輸入框
                        VStack(alignment: .leading, spacing: 12) {
                            Text("任務名稱")
                                .font(.system(size: 12, weight: .semibold)).tracking(1.2)
                                .foregroundStyle(.white.opacity(0.4))
                            
                            TextField("例如：晨間冥想、奧運特訓、深呼吸...", text: $title)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.white)
                                .tint(Color.fromCustomHex(selectedColorHex))
                        }
                        .padding(.all, 20)
                        .background(.white.opacity(0.03))
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color.fromCustomHex(selectedColorHex).opacity(0.2), lineWidth: 1)
                        )
                        .padding(.horizontal, 24)
                        
                        // 2. 週期與提醒機制設定 (💡 重構日期邏輯，解決不合理的選單選法)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("提醒週期設定")
                                .font(.system(size: 12, weight: .semibold)).tracking(1.2)
                                .foregroundStyle(.white.opacity(0.4))
                            
                            VStack(spacing: 16) {
                                Picker("週期", selection: $selectedRecurrence) {
                                    ForEach(RecurrenceType.allCases, id: \.self) { type in
                                        Text(type.rawValue).tag(type)
                                    }
                                }
                                .pickerStyle(.segmented)
                                
                                // 自訂年份：顯示幾年一次
                                if selectedRecurrence == .customYears {
                                    HStack {
                                        Text("每隔幾年提醒：")
                                            .font(.system(size: 14))
                                            .foregroundStyle(.white.opacity(0.7))
                                        Spacer()
                                        Stepper("\(customIntervalYears) 年", value: $customIntervalYears, in: 2...10)
                                            .foregroundColor(.white)
                                    }
                                }
                                
                                // 每月提醒：僅供選擇「幾號」，不干擾年份與月份
                                if selectedRecurrence == .monthly {
                                    HStack {
                                        Text("每月固定提醒日：")
                                            .font(.system(size: 14))
                                            .foregroundStyle(.white.opacity(0.7))
                                        Spacer()
                                        Picker("日期", selection: Binding(
                                            get: { Calendar.current.component(.day, from: targetDate) },
                                            set: { newDay in
                                                if let newDate = Calendar.current.date(bySetting: .day, value: newDay, of: targetDate) {
                                                    targetDate = newDate
                                                }
                                            }
                                        )) {
                                            ForEach(1...31, id: \.self) { day in
                                                Text("\(day) 號").tag(day)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                        .tint(.white)
                                    }
                                }
                                
                                // 單次提醒或自訂年份：才顯示完整的「年月日」日期選擇器
                                if selectedRecurrence == .once || selectedRecurrence == .customYears {
                                    DatePicker(
                                        "目標指定日期",
                                        selection: $targetDate,
                                        displayedComponents: .date
                                    )
                                    .environment(\.colorScheme, .dark)
                                    .font(.system(size: 14))
                                    .foregroundStyle(.white.opacity(0.7))
                                }
                            }
                            .padding(.all, 16)
                            .background(.white.opacity(0.03))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(.horizontal, 24)
                        
                        // 3. 霓虹色彩選取區
                        VStack(alignment: .leading, spacing: 12) {
                            Text("任務顏色")
                                .font(.system(size: 12, weight: .semibold)).tracking(1.2)
                                .foregroundStyle(.white.opacity(0.4))
                            
                            HStack(spacing: 18) {
                                ForEach(neonColors, id: \.self) { hex in
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                            selectedColorHex = hex
                                        }
                                    } label: {
                                        Circle()
                                            .fill(Color.fromCustomHex(hex))
                                            .frame(width: 38, height: 38)
                                            .shadow(color: Color.fromCustomHex(hex).opacity(selectedColorHex == hex ? 0.6 : 0), radius: 10)
                                            .overlay(
                                                Circle()
                                                    .stroke(.white, lineWidth: selectedColorHex == hex ? 2 : 0)
                                                    .scaleEffect(selectedColorHex == hex ? 1.15 : 1.0)
                                        )
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        
                        // 4. 圖示選取與搜尋區
                        VStack(alignment: .leading, spacing: 12) {
                            Text("任務標誌")
                                .font(.system(size: 12, weight: .semibold)).tracking(1.2)
                                .foregroundStyle(.white.opacity(0.4))
                            
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(.white.opacity(0.3))
                                TextField("搜尋圖示... (例如 heart, run)", text: $searchText)
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
                                            selectedIcon = icon
                                        } label: {
                                            Image(systemName: icon)
                                                .font(.system(size: 20))
                                                .foregroundStyle(selectedIcon == icon ? Color.fromCustomHex(selectedColorHex) : .white.opacity(0.4))
                                                .frame(width: 46, height: 46)
                                                .background(selectedIcon == icon ? Color.fromCustomHex(selectedColorHex).opacity(0.15) : Color.white.opacity(0.04))
                                                .clipShape(Circle())
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.fromCustomHex(selectedColorHex).opacity(selectedIcon == icon ? 0.5 : 0), lineWidth: 1)
                                                )
                                        }
                                    }
                                }
                                .padding(.vertical, 6)
                            }
                            .frame(maxHeight: 180)
                        }
                        .padding(.horizontal, 24)
                        
                        // 5. 建立與開啟按鈕
                        Button {
                            guard !title.isEmpty else { return }
                            
                            let newHabit = HabitModel(
                                title: title,
                                progress: 0,
                                colorHex: selectedColorHex,
                                iconName: selectedIcon,
                                recurrenceType: selectedRecurrence,
                                customIntervalYears: customIntervalYears,
                                targetDate: targetDate
                            )
                            modelContext.insert(newHabit)
                            dismiss()
                        } label: {
                            Text("開啟任務")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity, minHeight: 56)
                                .background(
                                    Color.fromCustomHex(selectedColorHex)
                                        .shadow(color: Color.fromCustomHex(selectedColorHex).opacity(0.4), radius: 20, y: 5)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        }
                        .disabled(title.isEmpty)
                        .opacity(title.isEmpty ? 0.4 : 1.0)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .viewBackgroundClearModifier()
    }
}

// 💡 專屬的安全色彩擴充功能
fileprivate extension Color {
    static func fromCustomHex(_ hexStr: String) -> Color {
        var cleanHex = hexStr.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cleanHex.hasPrefix("#") {
            cleanHex.remove(at: cleanHex.startIndex)
        }
        
        if cleanHex.count != 6 {
            return Color.gray
        }
        
        var rgbValue: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&rgbValue)
        
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        
        return Color(red: r, green: g, blue: b)
    }
}

// 💡 用於完全清除 Sheet 後方純白背景的乾淨擴充
fileprivate extension View {
    func viewBackgroundClearModifier() -> some View {
        if #available(iOS 16.4, *) {
            return self.presentationBackground(.clear)
        } else {
            return self.background(ClearBackgroundView())
        }
    }
}

fileprivate struct ClearBackgroundView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
}