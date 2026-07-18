import Foundation
import AudioToolbox
import UIKit

@MainActor
class SoundManager {
    static let shared = SoundManager()
    
    private init() {}
    
    /// 觸發輕微的觸覺回饋（用於一般點擊或進度微幅上升）
    func triggerLightImpact() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// 觸發成功的觸覺回饋（用於儀式充能完成、進度滿格）
    func triggerSuccessNotification() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }
    
    /// 播放預設的科技感「充電/上升」系統音效
    func playChargingSound() {
        // 使用 iOS 內建的系統音效 ID
        // 1104: 類似簡訊發送或小叮噹的上升音
        // 1057: 經典的系統叮一聲
        let systemSoundID: SystemSoundID = 1104
        AudioServicesPlaySystemSound(systemSoundID)
    }
    
    /// 播放儀式圓滿完成音效
    func playCompletionSound() {
        // 1313: 叮咚（代表成功或通知）
        let systemSoundID: SystemSoundID = 1313
        AudioServicesPlaySystemSound(systemSoundID)
    }
}