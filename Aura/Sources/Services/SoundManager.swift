import Foundation
import AudioToolbox
import UIKit

class SoundManager {
    static let shared = SoundManager()
    
    static func playSuccessSound() { shared.playCompletionSound() }
    static func playClickSound() { shared.playChargingSound() }
    
    init() {}
    
    func triggerLightImpact() {
        DispatchQueue.main.async {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred()
        }
    }
    
    func triggerSuccessNotification() {
        DispatchQueue.main.async {
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.success)
        }
    }
    
    /// 播放「點擊/充電上升」音效
    func playChargingSound() {
        // 改用 1104 (Tock 短音) 或 1157 (輕柔解鎖切換聲)
        let systemSoundID: SystemSoundID = 1157 
        AudioServicesPlaySystemSound(systemSoundID)
    }
    
    /// 播放「儀式圓滿完成」音效
    func playCompletionSound() {
        // 改用 1022 (新簡訊傳送完成的輕快「嗖」聲) 或 1407 (引導完成的科技流暢聲)
        // 這裡推薦 1022，很有任務達成的俐落空氣感，不會像敲鐘那麼突兀
        let systemSoundID: SystemSoundID = 1022 
        AudioServicesPlaySystemSound(systemSoundID)
    }
}