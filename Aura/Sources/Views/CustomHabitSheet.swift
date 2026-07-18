import SwiftUI
import SwiftData

struct CustomHabitSheet: View {
    @Environment(\.modelContext) private var modelContext[cite: 11]
    @Environment(\.dismiss) private var dismiss[cite: 11]
    
    @State private var title = ""[cite: 11]
    // 預設霓虹色：青色、粉紫、橘紅、螢光綠、鮮黃
    @State private var selectedColorHex = "#00F2FE" [cite: 11]
    // 預設 SF Symbol 圖示
    @State private var selectedIcon = "bolt.shield"[cite: 11]
    
    let neonColors = ["#00F2FE", "#F355DA", "#FF5E62", "#1ADF66", "#FFD200"][cite: 11]
    let icons = ["bolt.shield", "sparkles", "brain.headlight", "heart.text.square", "moon.stars"][cite: 11]

    var body: some View {
        NavigationStack {[cite: 11]
            ZStack {[cite: 11]
                // 深色極簡背景
                LinearGradient([cite: 11]
                    colors: [Color(hex: "#0B0D17"), Color(hex: "#16192B")],[cite: 11]
                    startPoint: .top,[cite: 11]
                    endPoint: .bottom[cite: 11]
                )[cite: 11]
                .ignoresSafeArea()[cite: 11]
                
                VStack(spacing: 24) {[cite: 11]
                    // 頂部裝飾條
                    Capsule()[cite: 11]
                        .fill(.white.opacity(0.15))[cite: 11]
                        .frame(width: 40, height: 4)[cite: 11]
                        .padding(.top, 12)[cite: 11]
                    
                    VStack(alignment: .leading, spacing: 6) {[cite: 11]
                        Text("創建新的任務")[cite: 11]
                            .font(.system(size: 24, weight: .bold, design: .rounded))[cite: 11]
                            .foregroundStyle(.white)[cite: 11]
                        Text("為你的日常更注入能量！")[cite: 11]
                            .font(.system(size: 14))[cite: 11]
                            .foregroundStyle(.white.opacity(0.5))[cite: 11]
                    }[cite: 11]
                    .frame(maxWidth: .infinity, alignment: .leading)[cite: 11]
                    .padding(.horizontal, 24)[cite: 11]
                    
                    // 輸入框卡片 - 採用極簡磨砂玻璃
                    VStack(alignment: .leading, spacing: 12) {[cite: 11]
                        Text("任務名稱")[cite: 11]
                            .font(.system(size: 12, weight: .semibold)).tracking(1.2)[cite: 11]
                            .foregroundStyle(.white.opacity(0.4))[cite: 11]
                        
                        TextField("例如：晨間冥想、閱讀、深呼吸...", text: $title)[cite: 11]
                            .font(.system(size: 16, weight: .medium))[cite: 11]
                            .foregroundStyle(.white)[cite: 11]
                            .tint(Color(hex: selectedColorHex))[cite: 11]
                    }[cite: 11]
                    .padding(.all, 20)[cite: 11]
                    .background(.white.opacity(0.03))[cite: 11]
                    .background(.ultraThinMaterial)[cite: 11]
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))[cite: 11]
                    .overlay([cite: 11]
                        RoundedRectangle(cornerRadius: 24, style: .continuous)[cite: 11]
                            .stroke(Color(hex: selectedColorHex).opacity(0.2), lineWidth: 1)[cite: 11]
                    )[cite: 11]
                    .padding(.horizontal, 24)[cite: 11]
                    
                    // 圖示選取區
                    VStack(alignment: .leading, spacing: 12) {[cite: 11]
                        Text("任務標誌")[cite: 11]
                            .font(.system(size: 12, weight: .semibold)).tracking(1.2)[cite: 11]
                            .foregroundStyle(.white.opacity(0.4))[cite: 11]
                        
                        HStack(spacing: 16) {[cite: 11]
                            ForEach(icons, id: \.self) { icon in[cite: 11]
                                Button {[cite: 11]
                                    selectedIcon = icon[cite: 11]
                                } label: {[cite: 11]
                                    Image(systemName: icon)[cite: 11]
                                        .font(.system(size: 20, weight: .medium))[cite: 11]
                                        .foregroundStyle(selectedIcon == icon ? Color(hex: selectedColorHex) : .white.opacity(0.4))[cite: 11]
                                        .frame(width: 46, height: 46)[cite: 11]
                                        .background(selectedIcon == icon ? Color(hex: selectedColorHex).opacity(0.15) : Color.white.opacity(0.05))[cite: 11]
                                        .clipShape(Circle())[cite: 11]
                                        .overlay([cite: 11]
                                            Circle()[cite: 11]
                                                .stroke(Color(hex: selectedColorHex).opacity(selectedIcon == icon ? 0.6 : 0), lineWidth: 1)[cite: 11]
                                        )[cite: 11]
                                }[cite: 11]
                            }[cite: 11]
                        }[cite: 11]
                    }[cite: 11]
                    .frame(maxWidth: .infinity, alignment: .leading)[cite: 11]
                    .padding(.horizontal, 24)[cite: 11]
                    
                    // 霓虹色彩選取區
                    VStack(alignment: .leading, spacing: 12) {[cite: 11]
                        Text("任務顏色")[cite: 11]
                            .font(.system(size: 12, weight: .semibold)).tracking(1.2)[cite: 11]
                            .foregroundStyle(.white.opacity(0.4))[cite: 11]
                        
                        HStack(spacing: 18) {[cite: 11]
                            ForEach(neonColors, id: \.self) { hex in[cite: 11]
                                Button {[cite: 11]
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {[cite: 11]
                                        selectedColorHex = hex[cite: 11]
                                    }[cite: 11]
                                } label: {[cite: 11]
                                    Circle()[cite: 11]
                                        .fill(Color(hex: hex))[cite: 11]
                                        .frame(width: 38, height: 38)[cite: 11]
                                        .shadow(color: Color(hex: hex).opacity(selectedColorHex == hex ? 0.6 : 0), radius: 10)[cite: 11]
                                        .overlay([cite: 11]
                                            Circle()[cite: 11]
                                                .stroke(.white, lineWidth: selectedColorHex == hex ? 2 : 0)[cite: 11]
                                                .scaleEffect(selectedColorHex == hex ? 1.15 : 1.0)[cite: 11]
                                        )[cite: 11]
                                }[cite: 11]
                            }[cite: 11]
                        }[cite: 11]
                    }[cite: 11]
                    .frame(maxWidth: .infinity, alignment: .leading)[cite: 11]
                    .padding(.horizontal, 24)[cite: 11]
                    
                    Spacer()[cite: 11]
                    
                    // 建立按鈕
                    Button {[cite: 11]
                        guard !title.isEmpty else { return }[cite: 11]
                        
                        // 💡 修正關鍵：依據錯誤訊息調整屬性賦值順序，確保 colorHex 在前，iconName 在後
                        let newHabit = HabitModel(
                            title: title,
                            colorHex: selectedColorHex,
                            iconName: selectedIcon
                        )
                        modelContext.insert(newHabit)[cite: 11]
                        dismiss()[cite: 11]
                    } label: {[cite: 11]
                        Text("開啟任務")[cite: 11]
                            .font(.system(size: 16, weight: .semibold, design: .rounded))[cite: 11]
                            .foregroundStyle(.black)[cite: 11]
                            .frame(maxWidth: .infinity, minHeight: 56)[cite: 11]
                            .background([cite: 11]
                                Color(hex: selectedColorHex)[cite: 11]
                                    .shadow(color: Color(hex: selectedColorHex).opacity(0.4), radius: 20, y: 5)[cite: 11]
                            )[cite: 11]
                            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))[cite: 11]
                    }[cite: 11]
                    .disabled(title.isEmpty)[cite: 11]
                    .opacity(title.isEmpty ? 0.4 : 1.0)[cite: 11]
                    .padding(.horizontal, 24)[cite: 11]
                    .padding(.bottom, 24)[cite: 11]
                }
            }
            .navigationBarHidden(true)[cite: 11]
        }
    }
}

// 方便 Color 直接讀取 Hex 的擴充
extension Color {
    init(hex: String) {[cite: 11]
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)[cite: 11]
        var int: UInt64 = 0[cite: 11]
        Scanner(string: hex).scanHexInt64(&int)[cite: 11]
        let a, r, g, b: UInt64[cite: 11]
        switch hex.count {[cite: 11]
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)[cite: 11]
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)[cite: 11]
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)[cite: 11]
        default:[cite: 11]
            (a, r, g, b) = (255, 255, 255, 255)[cite: 11]
        }
        self.init([cite: 11]
            .sRGB,[cite: 11]
            let red: Double(r) / 255,[cite: 11]
            let green: Double(g) / 255,[cite: 11]
            let blue:  Double(b) / 255,[cite: 11]
            let opacity: Double(a) / 255[cite: 11]
        )[cite: 11]
    }
}