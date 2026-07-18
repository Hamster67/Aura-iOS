import Foundation
import SwiftData

@Model
final class HabitModel {
    var id: UUID = UUID()
    var title: String = ""
    var progress: Double = 0
    var colorHex: String = "47D7FF"
    var iconName: String = "sparkles"
    
    // 🔥 新增：每日打卡與連勝
    var streakCount: Int = 0
    var lastCheckInDate: Date?
    
    // ⏰ 新增：每週特定星期與時間提醒 (1=日, 2=一, 3=二, 4=三, 5=四, 6=五, 7=六)
    var reminderDays: [Int] = [] 
    var reminderTime: Date?
    
    // 💤 新增：暫停與略過機制
    var isPaused: Bool = false
    var skipUntilDate: Date?

    init(
        id: UUID = UUID(),
        title: String,
        progress: Double = 0,
        colorHex: String,
        iconName: String
    ) {
        self.id = id
        self.title = title
        self.progress = min(max(progress, 0), 1)
        self.colorHex = colorHex
        self.iconName = iconName
        
        // 初始狀態
        self.streakCount = 0
        self.isPaused = false
    }

    var isComplete: Bool { progress >= 1 }
    
    /// 檢查今天此習慣是否需要打卡（排除暫停、略過、或未排程的日期）
    var isRequiredToday: Bool {
        if isPaused { return false }
        if let skipUntil = skipUntilDate, Date() < skipUntil { return false }
        
        let currentDay = Calendar.current.component(.weekday, from: Date())
        return reminderDays.isEmpty || reminderDays.contains(currentDay)
    }
    
    /// 觸發每日打卡與連勝邏輯
    func checkIn() {
        let calendar = Calendar.current
        let now = Date()
        
        if let lastDate = lastCheckInDate {
            if calendar.isDateInYesterday(lastDate) {
                streakCount += 1
            } else if !calendar.isDateInToday(lastDate) {
                streakCount = 1 // 斷開後重新開始
            }
        } else {
            streakCount = 1 // 首次打卡
        }
        
        lastCheckInDate = now
        progress = 1.0
    }
}