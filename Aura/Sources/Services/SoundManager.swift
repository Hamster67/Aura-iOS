import AudioToolbox

enum SoundManager {
    /// 播放標準輕量點擊聲 (iOS 系統內建 Tock 聲)
    static func playClickSound() {
        AudioServicesPlaySystemSound(1104)
    }
    
    /// 播放清脆確認提示音 (適用於蓄力/任務成功)
    static func playSuccessSound() {
        AudioServicesPlaySystemSound(1407)
    }
}