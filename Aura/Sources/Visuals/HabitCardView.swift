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
            // 關鍵修正 1：高優先級手勢給選單按鈕，防止被外層長按/連點手勢攔截
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
        // 點擊卡片其餘空白處觸發儀式
        .onTapGesture {
            onTriggerRitual()
        }
        // 彈出編輯視窗
        .sheet(isPresented: $isEditing) {
            EditHabitSheet(habit: habit)
        }
    }
}

/// 獨立的編輯意圖視窗
struct EditHabitSheet: View {
    @Bindable var habit: HabitModel
    @Environment(\.dismiss) private var dismiss
    
    let neonColors = ["#00F2FE", "#F355DA", "#FF5E62", "#1ADF66", "#FFD200"]
    let icons = ["bolt.shield", "sparkles", "brain.headlight", "heart.text.square", "moon.stars"]

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "#0B0D17"), Color(hex: "#16192B")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Capsule()
                        .fill(.white.opacity(0.15))
                        .frame(width: 40, height: 4)
                        .padding(.top, 12)
                    
                    Text("修正意圖核心")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                    
                    // 輸入框
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
                    
                    // 圖示
                    VStack(alignment: .leading, spacing: 12) {
                        Text("變更標誌")
                            .font(.system(size: 12, weight: .semibold)).tracking(1.2)
                            .foregroundStyle(.white.opacity(0.4))
                        
                        HStack(spacing: 16) {
                            ForEach(icons, id: \.self) { icon in
                                Button {
                                    habit.iconName = icon
                                } label: {
                                    Image(systemName: icon)
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundStyle(habit.iconName == icon ? Color(hex: habit.colorHex) : .white.opacity(0.4))
                                        .frame(width: 46, height: 46)
                                        .background(habit.iconName == icon ? Color(hex: habit.colorHex).opacity(0.15) : Color.white.opacity(0.05))
                                        .clipShape(Circle())
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    
                    // 顏色
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
                                        .frame(width: 38, height: 38)
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