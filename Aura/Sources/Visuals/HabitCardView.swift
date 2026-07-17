import SwiftUI

struct HabitCardView: View {
    let habitName: String
    let habitStreak: Int
    let habitProgress: Double
    
    var delete: () -> Void
    var onChargeUpdate: (Double, Bool) -> Void
    
    @State private var isLongPressing = false
    @State private var chargeProgress: Double = 0.0
    @State private var timer: Timer? = nil
    @State private var showDeleteConfirm = false
    
    var body: some View {
        HStack {
            // 左側資訊區：長按此處會彈出選單
            VStack(alignment: .leading, spacing: 8) {
                Text(habitName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("\(habitStreak) 天連續")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .contentShape(Rectangle()) // 確保文字間隙也能觸發選單
            
            Spacer()
            
            // 右側充電按鈕：透過高優先權手勢完全阻斷外層的 contextMenu
            ProgressCircleView(
                chargeProgress: chargeProgress,
                isLongPressing: isLongPressing
            )
            .scaleEffect(isLongPressing ? 1.15 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isLongPressing)
            // 使用高優先權的長按與拖動組合，徹底把 contextMenu 擋在外面
            .highPriorityGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isLongPressing {
                            isLongPressing = true
                            beginCharging()
                        }
                    }
                    .onEnded { _ in
                        isLongPressing = false
                        endCharging()
                    }
            )
            // 加上空點擊，防止長按穿透到後方的卡片背景上
            .onTapGesture {} 
        }
        .padding()
        // 液態玻璃質感背景
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white.opacity(0.02))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.2), .white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        // 卡片主體的選單（現在按鈕長按不會再誤觸它了）
        .contextMenu {
            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Label("刪除習慣", systemImage: "trash")
            }
        }
        .alert("刪除習慣", isPresented: $showDeleteConfirm) {
            Button("取消", role: .cancel) {}
            Button("刪除", role: .destructive) { delete() }
        } message: {
            Text("確定要刪除「\(habitName)」嗎？此動作無法復原。")
        }
    }
    
    private func beginCharging() {
        chargeProgress = habitProgress
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            if chargeProgress < 1.0 {
                chargeProgress = min(chargeProgress + 0.02, 1.0)
                onChargeUpdate(chargeProgress, true)
                
                if chargeProgress >= 1.0 {
                    triggerSuccessVibration()
                    endCharging()
                }
            }
        }
    }
    
    private func endCharging() {
        timer?.invalidate()
        timer = nil
        isLongPressing = false
        
        if chargeProgress < 1.0 {
            withAnimation(.easeOut(duration: 0.3)) {
                chargeProgress = habitProgress
            }
            onChargeUpdate(habitProgress, false)
        }
    }
    
    private func triggerSuccessVibration() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

private struct ProgressCircleView: View {
    let chargeProgress: Double
    let isLongPressing: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 4)
                .frame(width: 60, height: 60)
            
            Circle()
                .trim(from: 0, to: chargeProgress)
                .stroke(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 60, height: 60)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.1), value: chargeProgress)
            
            LiquidIcon(progress: chargeProgress, isCharging: isLongPressing)
                .frame(width: 30, height: 30)
        }
        .contentShape(Circle()) // 確保圓形範圍內的事件都被精準捕捉
    }
}

private struct LiquidIcon: View {
    let progress: Double
    let isCharging: Bool
    
    var body: some View {
        Image(systemName: progress >= 1.0 ? "checkmark.circle.fill" : "bolt.fill")
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(progress >= 1.0 ? .green : (isCharging ? .yellow : .white))
    }
}