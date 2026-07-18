import Foundation
import AudioToolbox
import UIKit

class SoundManager {
    static let shared = SoundManager()
    
    // 移除類別層級的 @MainActor，改在靜態與實例方法上維持非隔離（Non-isolated）安全呼叫
    static func playSuccessSound() { shared.playCompletionSound() }
    static func playClickSound() { shared.playChargingSound() }
    
    init() {}
    
    /// 觸發輕微的觸覺回饋（內部強制在主執行緒執行，確保 UI 安全）
    func triggerLightImpact() {
        DispatchQueue.main.async {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred()
        }
    }
    
    /// 觸發成功的觸覺回饋（內部強制在主執行緒執行）
    func triggerSuccessNotification() {
        DispatchQueue.main.async {
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.success)
        }
    }
    
    /// 播放預設的科技感「充電/上升」系統音效（底層為 C 語言 API，執行緒安全）
    func playChargingSound() {
        let systemSoundID: SystemSoundID = 1104
        AudioServicesPlaySystemSound(systemSoundID)
    }
    
    /// 播放儀式圓滿完成音效（執行緒安全）
    func playCompletionSound() {
        let systemSoundID: SystemSoundID = 1313
        AudioServicesPlaySystemSound(systemSoundID)
    }
}