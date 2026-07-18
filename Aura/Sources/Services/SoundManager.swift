import Foundation
import AudioToolbox
import UIKit

@MainActor
class SoundManager {
    static let shared = SoundManager()
    
    // 提供給外部單例與靜態呼叫的兼顧設計
    static func playSuccessSound() { shared.playCompletionSound() }
    static func playClickSound() { shared.playChargingSound() }
    
    init() {}
    
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
        let systemSoundID: SystemSoundID = 1104
        AudioServicesPlaySystemSound(systemSoundID)
    }
    
    /// 播放儀式圓滿完成音效
    func playCompletionSound() {
        let systemSoundID: SystemSoundID = 1313
        AudioServicesPlaySystemSound(systemSoundID)
    }
}