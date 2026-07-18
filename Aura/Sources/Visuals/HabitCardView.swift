import SwiftUI

struct HabitCardView: View {
    let habitName: String
    let habitStreak: Int
    let habitProgress: Double
    let completionMethod: Int // 0: 三擊, 1: 長按
    
    var delete: () -> Void
    var onChargeUpdate: (Double, Bool) -> Void
    
    @State private var chargeProgress: Double = 0.0
    @State private var timer: Timer? = nil
    
    // 選單控制
    @State private var showOptions = false
    
    // 連點熱烈度計量 (三擊模式)
    @State private var tapCount = 0
    @State private var visualIntensity: CGFloat = 1.0
    
    // iOS 6 垃圾桶吸入動畫狀態
    @State private var isSuckingIntoTrash = false
    @State private var trashAnimationProgress: CGFloat = 0.0

    var body: some View {
        if trashAnimationProgress < 1.0 {
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
                
                // 右側多功能狀態圓圈
                ZStack {
                    Circle()
                        .stroke(Color.black.opacity(0.05), lineWidth: 4)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: chargeProgress)
                        .stroke(
                            LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                    
                    // 核心圖示
                    Image(systemName: chargeProgress >= 1.0 ? "checkmark.circle.fill" : "ellipsis.circle.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(chargeProgress >= 1.0 ? .green : .black.opacity(0.6))
                }
                .scaleEffect(visualIntensity)
                .animation(.spring(response: 0.2, dampingFraction: 0.4), value: visualIntensity)
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 24)
            
            // --- iOS 26 淺色 Liquid Glass 頂級質感核心（多層內陰影與微觀白乳膠感） ---
            .background(
                ZStack {
                    // 系統厚重濾鏡層
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(.ultraThinMaterial)
                    
                    // 內部均勻的微白乳膠反光，取代死板邊緣
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.6), .white.opacity(0.2)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        // 內陰影效果：製造出玻璃本身的厚度與重量
                        .shadow(color: .white.opacity(0.9), radius: 10, x: 0, y: -5)
                        .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 5)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
            )
            // 點擊整張卡片直接跳出「點擊選單」，完美避開手勢衝突
            .onTapGesture {
                showOptions = true
            }
            
            // iOS 6 垃圾桶吸入扭曲效果器
            .offset(x: isSuckingIntoTrash ? 150 : 0, y: isSuckingIntoTrash ? 200 : 0)
            .scaleEffect(isSuckingIntoTrash ? 0.05 : 1.0)
            .rotationEffect(.degrees(isSuckingIntoTrash ? 45 : 0))
            .opacity(isSuckingIntoTrash ? 0.0 : 1.0)
            
            // 點擊選單 (取代原來的彈出選單，介面更乾淨)
            .confirmationDialog("選擇對「\(habitName)」的操作", isPresented: $showOptions, titleVisibility: .visible) {
                Button(completionMethod == 0 ? "連點完成模式" : "長按完成模式") {
                    triggerCompletionWorkflow()
                }
                Button("刪除任務", role: .destructive) {
                    triggeriOS6TrashAnimation()
                }
                Button("取消", role: .cancel) {}
            }
        }
    }
    
    // 依據主畫面設定，執行對應的完成儀式
    private func triggerCompletionWorkflow() {
        if completionMethod == 0 {
            // 三擊模式：每按一下越來越大、越熱烈
            tapCount += 1
            visualIntensity = 1.0 + (CGFloat(tapCount) * 0.15)
            
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred(intensity: CGFloat(tapCount) * 0.33)
            
            withAnimation(.linear(duration: 0.15)) {
                chargeProgress = min(Double(tapCount) * 0.34, 1.0)
            }
            onChargeUpdate(chargeProgress, false)
            
            if tapCount >= 3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    tapCount = 0
                    visualIntensity = 1.0
                }
            }
        } else {
            // 長按充電模式：時間越久越膨脹、越熱烈
            visualIntensity = 1.3
            chargeProgress = habitProgress
            timer?.invalidate()
            
            timer = Timer.scheduledTimer(withTimeInterval: 0.04, repeats: true) { _ in
                if chargeProgress < 1.0 {
                    chargeProgress = min(chargeProgress + 0.03, 1.0)
                    onChargeUpdate(chargeProgress, true)
                    
                    // 隨著時間增加震動強度
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    
                    if chargeProgress >= 1.0 {
                        let successGen = UINotificationFeedbackGenerator()
                        successGen.notificationOccurred(.success)
                        endCharging()
                    }
                }
            }
        }
    }
    
    private func endCharging() {
        timer?.invalidate()
        timer = nil
        withAnimation(.spring()) { visualIntensity = 1.0 }
    }
    
    // iOS 6 照片丟到垃圾桶的扭曲與吸入物理動畫
    private func triggeriOS6TrashAnimation() {
        let haptic = UIImpactFeedbackGenerator(style: .rigid)
        haptic.impactOccurred()
        
        withAnimation(.customSuckAnimation) {
            isSuckingIntoTrash = true
        }
        
        // 動態播放完畢後，真正的執行 SwiftData 刪除
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            trashAnimationProgress = 1.0
            delete()
        }
    }
}

// 專為 iOS 6 吸入特效客製化的貝茲曲線
extension Animation {
    static var customSuckAnimation: Animation {
        .timingCurve(0.55, 0.055, 0.675, 0.19, duration: 0.55)
    }
}