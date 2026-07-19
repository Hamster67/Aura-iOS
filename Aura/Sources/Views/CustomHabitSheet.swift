import SwiftUI
import SwiftData

struct CustomHabitSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var selectedColorHex = "#00F2FE" 
    @State private var selectedIcon = "bolt.shield"
    
    @State private var selectedRecurrence: RecurrenceType = .daily
    @State private var customIntervalYears = 4
    @State private var targetDate = Date()
    
    @State private var searchText = ""
    let columns = [GridItem(.adaptive(minimum: 50))]
    
    let neonColors = ["00F2FE", "F355DA", "FF5E62", "1ADF66", "FFD200"]
    
    let icons = [
        "bolt.shield", "sparkles", "brain.headlight", "heart.text.square", "moon.stars", "flame", "drop.fill", "sun.max",
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
                    colors: [Color("#0B0D17").opacity(0.85), Color("#16192B").opacity(0.85)],
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
                                .tint(Color(selectedColorHex))
                        }
                        .padding(.all, 20)
                        .background(.white.opacity(0.03))
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color(selectedColorHex).opacity(0.2), lineWidth: 1)
                        )
                        .padding(.horizontal, 24)
                        
                        // 2. 週期與提醒機制設定
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
                                
                                if selectedRecurrence != .daily {
                                    DatePicker(
                                        selectedRecurrence == .monthly ? "每月提醒日" : "目標指定日期",
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
                                            .fill(Color(hex))
                                            .frame(width: 38, height: 38)
                                            .shadow(color: Color(hex).opacity(selectedColorHex == hex ? 0.6 : 0), radius: 10)
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
                                                .foregroundStyle(selectedIcon == icon ? Color(selectedColorHex) : .white.opacity(0.4))
                                                .frame(width: 46, height: 46)
                                                .background(selectedIcon == icon ? Color(selectedColorHex).opacity(0.15) : Color.white.opacity(0.04))
                                                .clipShape(Circle())
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color(selectedColorHex).opacity(selectedIcon == icon ? 0.5 : 0), lineWidth: 1)
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
                                    Color(selectedColorHex)
                                        .shadow(color: Color(selectedColorHex).opacity(0.4), radius: 20, y: 5)
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
        .presentationBackground(.clear) // 🔥 強制移除系統底層純白背景，還原毛玻璃
    }
}