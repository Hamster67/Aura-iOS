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
            // 左側：圖示與核心名稱
            HStack(spacing: 14) {
                Image(systemName: habit.iconName)
                    .font(.system(size: 20))
                    .foregroundStyle(Color(hex: habit.colorHex))
                    .frame(width: 44, height: 44)
                    .background(Color(hex: habit.colorHex).opacity(0.12), in: Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("進度：\(Int(habit.progress * 100))%")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            
            Spacer()
            
            // 右側：操作選單（編輯/刪除）
            Menu {
                Button {
                    isEditing = true
                } label: {
                    Label("編輯意圖", systemImage: "pencil")
                }
                
                Button(role: .destructive) {
                    withAnimation { delete() }
                } label: {
                    Label("刪除核心", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.05), in: Circle())
            }
            .highPriorityGesture(TapGesture())
        }
        .padding(.all, 20)
        .background(.white.opacity(0.02))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
        .onTapGesture {
            onTriggerRitual()
        }
        .sheet(isPresented: $isEditing) {
            EditHabitSheet(habit: habit)
        }
    }
}

/// 升級版：支援搜尋數百種 SF Symbols 的編輯視窗
struct EditHabitSheet: View {
    @Bindable var habit: HabitModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    
    let neonColors = ["#00F2FE", "#F355DA", "#FF5E62", "#1ADF66", "#FFD200"]
    
    // 精選常用捷徑/任務圖示資料庫 (涵蓋健康、正念、工作、生活、運動)
    let allSymbols = [
        // 核心與能量
        "bolt.shield", "sparkles", "brain.headlight", "heart.text.square", "moon.stars", "flame", "drop.fill", "sun.max",
        // 健康與生活
        "figure.mind.and.body", "figure.walk", "figure.run", "heart.fill", "pills", "bed.double.fill", "lungs.fill",
        // 工作與學習
        "book.closed", "doc.text", "laptopcomputer", "terminal", "pencil.and.outline", "graduationcap", "briefcase",
        // 儀式感與日常
        "cup.and.saucer", "fork.knife", "wineglass", "hourglass", "timer", "alarm", "bell", "calendar",
        // 靜心與環境
        "leaf", "tree", "wind", "guitars", "music.note", "house", "infinity", "scope", "eye"
    ]
    
    // 過濾後的圖示清單
    var filteredSymbols: [String] {
        if searchText.isEmpty {
            return allSymbols
        } else {
            // 如果使用者搜尋，可以即時匹配
            return allSymbols.filter { $0.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    // 網格佈局（一行 5 個）
    let columns = [GridItem(.adaptive(minimum: 50))]

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "#0B0D17"), Color(hex: "#16192B")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Capsule()
                        .fill(.white.opacity(0.15))
                        .frame(width: 40, height: 4)
                        .padding(.top, 12)
                    
                    Text("修正意圖核心")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                    
                    // 1. 意圖名稱輸入框
                    VStack(alignment: .leading, spacing: 12) {
                        Text("意圖名稱")
                            .font(.system(size: 12, weight: .semibold)).tracking(1.2)
                            .foregroundStyle(.white.opacity(0.4))
                        
                        TextField("輸入新名稱...", text: $habit.title)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white)
                            .tint(Color(hex: habit.colorHex))
                    }
                    .padding(.all, 20)
                    .background(.white.opacity(0.03))
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color(hex: habit.colorHex).opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                    
                    // 2. 顏色調整
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
                                        .fill(Color(hex: hex))
                                        .frame(width: 36, height: 36)
                                        .overlay(
                                            Circle()
                                                .stroke(.white, lineWidth: habit.colorHex == hex ? 2 : 0)
                                                .scaleEffect(habit.colorHex == hex ? 1.15 : 1.0)
                                        )
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    
                    // 3. 圖示搜尋與滾動選擇區
                    VStack(alignment: .leading, spacing: 12) {
                        Text("變更標誌（支援搜尋捷徑圖示）")
                            .font(.system(size: 12, weight: .semibold)).tracking(1.2)
                            .foregroundStyle(.white.opacity(0.4))
                        
                        // 搜尋列
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.white.opacity(0.3))
                            TextField("搜尋圖示... (輸入英文例如 heart, run)", text: $searchText)
                                .font(.system(size: 14))
                                .foregroundStyle(.white)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .background(.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        // 可滾動的網格
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 14) {
                                ForEach(filteredSymbols, id: \.self) { icon in
                                    Button {
                                        habit.iconName = icon
                                    } label: {
                                        Image(systemName: icon)
                                            .font(.system(size: 20))
                                            .foregroundStyle(habit.iconName == icon ? Color(hex: habit.colorHex) : .white.opacity(0.4))
                                            .frame(width: 46, height: 46)
                                            .background(habit.iconName == icon ? Color(hex: habit.colorHex).opacity(0.15) : Color.white.opacity(0.04))
                                            .clipShape(Circle())
                                            .overlay(
                                                Circle()
                                                    .stroke(Color(hex: habit.colorHex).opacity(habit.iconName == icon ? 0.5 : 0), lineWidth: 1)
                                            )
                                    }
                                }
                            }
                            .padding(.vertical, 6)
                        }
                        .frame(maxHeight: 180) // 限制高度，防止壓縮到其他 UI
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
                            .background(Color(hex: habit.colorHex))
                            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
        }
    }
}