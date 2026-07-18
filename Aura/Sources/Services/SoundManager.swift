import Foundation
import UIKit

class SoundManager {
    static let shared = SoundManager()
    
    // 讓外部呼叫保持不變，但內部不執行任何聲音播放
    static func playSuccessSound() { 
        shared.triggerSuccessNotification() 
    }
    
    static func playClickSound() { 
        shared.triggerLightImpact() 
    }
    
    init() {}
    
    /// 觸發輕微的觸覺回饋（用於充能點擊、介面微幅互動）
    func triggerLightImpact() {
        DispatchQueue.main.async {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred()
        }
    }
    
    /// 觸發成功的觸覺回饋（用於儀式圓滿完成、進度滿格）
    func triggerSuccessNotification() {
        DispatchQueue.main.async {
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.success)
        }
    }
}