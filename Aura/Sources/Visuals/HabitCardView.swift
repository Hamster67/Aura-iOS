import SwiftUI

struct HabitCardView: View {
    let habitName: String
    let habitStreak: Int
    let habitProgress: Double
    
    var delete: () -> Void
    var triggerRitual: () -> Void // 觸發全螢幕互動
    
    @State private var showOptions = false
    @State private var isSuckingIntoTrash = false
    @State private var isRemoved = false

    var body: some View {
        if !isRemoved {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(habitName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black.opacity(0.85))
                    
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("\(habitStreak) 天連續")
                            .font(.subheadline)
                            .foregroundColor(.black.opacity(0.4))
                    }
                }
                
                Spacer()
                
                // 右側進度指示器（純顯示，不綁定複雜手勢）
                ZStack {
                    Circle()
                        .stroke(Color.black.opacity(0.05), lineWidth: 4)
                        .frame(width: 50, height: 50)
                    Circle()
                        .trim(from: 0, to: habitProgress)
                        .stroke(
                            LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(-90))
                    
                    Image(systemName: habitProgress >= 1.0 ? "checkmark.circle.fill" : "circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(habitProgress >= 1.0 ? .green : .black.opacity(0.1))
                }
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 24)
            
            // iOS 26 淺色流體玻璃質感（白色乳膠反光與內陰影）
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(.ultraThinMaterial)
                    
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.6), .white.opacity(0.2)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .white.opacity(0.9), radius: 10, x: 0, y: -5)
                        .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 5)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
            )
            
            // 1. 打開選單：點擊整張卡片彈出選單
            .onTapGesture {
                showOptions = true
            }
            
            // iOS 6 垃圾桶吸入扭曲動畫器
            .offset(x: isSuckingIntoTrash ? 180 : 0, y: isSuckingIntoTrash ? 250 : 0)
            .scaleEffect(isSuckingIntoTrash ? 0.02 : 1.0)
            .rotationEffect(.degrees(isSuckingIntoTrash ? 60 : 0))
            .opacity(isSuckingIntoTrash ? 0.0 : 1.0)
            
            // 系統選單
            .confirmationDialog("操作「\(habitName)」", isPresented: $showOptions, titleVisibility: .visible) {
                Button("完成此習慣") {
                    triggerRitual() // 導向全螢幕
                }
                Button("刪除任務", role: .destructive) {
                    triggeriOS6TrashAnimation()
                }
                Button("取消", role: .cancel) {}
            }
        }
    }
    
    private func triggeriOS6TrashAnimation() {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        withAnimation(.timingCurve(0.55, 0.055, 0.675, 0.19, duration: 0.55)) {
            isSuckingIntoTrash = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            isRemoved = true
            delete()
        }
    }
}