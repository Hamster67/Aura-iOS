import SwiftUI
import SwiftData

struct CustomHabitSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    // 預設霓虹色：青色、粉紫、橘紅、螢光綠、鮮黃
    @State private var selectedColorHex = "#00F2FE" 
    
    let neonColors = ["#00F2FE", "#F355DA", "#FF5E62", "#1ADF66", "#FFD200"]
    let colorNames = ["冰晶青", "霓虹粉", "烈焰紅", "極光綠", "曜石黃"]

    var body: some View {
        NavigationStack {
            ZStack {
                // 深色極簡背景，帶有微弱的漸層
                LinearGradient(
                    colors: [Color(hex: "#0B0D17"), Color(hex: "#16192B")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 28) {
                    // 頂部裝飾條
                    Capsule()
                        .fill(.white.opacity(0.15))
                        .frame(width: 40, height: 4)
                        .padding(.top, 12)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("設定新的意圖")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("為你的日常儀式注入能量核心")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    
                    // 輸入框卡片 - 採用極簡磨砂玻璃
                    VStack(alignment: .leading, spacing: 12) {
                        Text("意圖名稱")
                            .font(.system(size: 12, weight: .semibold)).tracking(1.2)
                            .foregroundStyle(.white.opacity(0.4))
                        
                        TextField("例如：晨間冥想、閱讀、深呼吸...", text: $title)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white)
                            .tint(Color(hex: selectedColorHex))
                    }
                    .padding(.all, 20)
                    .background(.white.opacity(0.03))
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color(hex: selectedColorHex).opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                    
                    // 霓虹色彩選取區
                    VStack(alignment: .leading, spacing: 16) {
                        Text("能量色彩")
                            .font(.system(size: 12, weight: .semibold)).tracking(1.2)
                            .foregroundStyle(.white.opacity(0.4))
                        
                        HStack(spacing: 18) {
                            ForEach(0..<neonColors.count, id: \.self) { index in
                                let hex = neonColors[index]
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        selectedColorHex = hex
                                    }
                                } label: {
                                    Circle()
                                        .fill(Color(hex: hex))
                                        .frame(width: 38, height: 38)
                                        .shadow(color: Color(hex: hex).opacity(selectedColorHex == hex ? 0.6 : 0), radius: 10)
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
                    
                    Spacer()
                    
                    // 建立按鈕
                    Button {
                        guard !title.isEmpty else { return }
                        let newHabit = HabitModel(title: title, colorHex: selectedColorHex)
                        modelContext.insert(newHabit)
                        dismiss()
                    } label: {
                        Text("開啟意圖核心")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .background(
                                Color(hex: selectedColorHex)
                                    .shadow(color: Color(hex: selectedColorHex).opacity(0.4), radius: 20, y: 5)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    }
                    .disabled(title.isEmpty)
                    .opacity(title.isEmpty ? 0.4 : 1.0)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// 方便 Color 直接讀取 Hex 的擴充
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 1)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}