import Foundation
import SwiftData

/// 提醒與打卡的重複週期類型
public enum RecurrenceType: String, Codable, CaseIterable {
    case daily = "每日"
    case monthly = "每月"
    case yearly = "每年"
    case customYears = "每幾年"
}

@Model
final class HabitModel {
    var id: UUID = UUID()
    var title: String = ""
    var progress: Double = 0
    var colorHex: String = "47D7FF"
    var iconName: String = "sparkles"
    
    // 🔥 全新週期提醒設定
    var recurrenceType: RecurrenceType = RecurrenceType.daily
    var customIntervalYears: Int = 4 // 專為奧運等長週期設計，預設 4 年
    var targetDate: Date = Date()    // 用於記錄月打卡日、年打卡日、或特定長週期起算日
    var reminderTime: Date?          // 當天的具體提醒時間點
    
    // 🔥 打卡與連勝防禦機制
    var streakCount: Int = 0
    var lastCheckInDate: Date?       // 上次打卡完成日期[cite: 8]
    var lastActionDate: Date?        // 上次採取行動的日期（包含完成與略過）
    var lastActionStatus: String?    // "completed" 或 "skipped"
    
    // 💤 暫停與略過機制[cite: 8]
    var isPaused: Bool = false //[cite: 8]
    var skipUntilDate: Date? //[cite: 8]

    init(
        id: UUID = UUID(),
        title: String,
        progress: Double = 0,
        colorHex: String,
        iconName: String,
        recurrenceType: RecurrenceType = .daily,
        customIntervalYears: Int = 4,
        targetDate: Date = Date(),
        reminderTime: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.progress = min(max(progress, 0), 1) //[cite: 8]
        self.colorHex = colorHex
        self.iconName = iconName
        
        self.recurrenceType = recurrenceType
        self.customIntervalYears = customIntervalYears
        self.targetDate = targetDate
        self.reminderTime = reminderTime
        
        self.streakCount = 0 //[cite: 8]
        self.isPaused = false //[cite: 8]
    }

    var isComplete: Bool { progress >= 1 } //[cite: 8]
    
    /// 檢查當前日期此提醒事項是否需要處理（排除已打卡、暫停或略過的狀態）[cite: 8]
    var isRequiredToday: Bool {
        if isPaused { return false } //[cite: 8]
        if let skipUntil = skipUntilDate, Date() < skipUntil { return false } //[cite: 8]
        
        let calendar = Calendar.current
        let now = Date()
        
        // 如果今天已經採取過行動（打卡或略過），則今日不再重複要求
        if let lastAction = lastActionDate, calendar.isDateInToday(lastAction) {
            return false
        }
        
        switch recurrenceType {
        case .daily:
            return true
            
        case .monthly:
            // 檢查今天是不是設定的那個打卡日（例如每月的 15 號）
            return calendar.component(.day, from: targetDate) == calendar.component(.day, from: now)
            
        case .yearly:
            // 檢查今天是不是設定的月份與日期（例如每年的 8 月 8 日）
            return calendar.isDate(now, equalTo: targetDate, toGranularity: .month) &&
                   calendar.component(.day, from: targetDate) == calendar.component(.day, from: now)
            
        case .customYears:
            // 檢查是否符合特定年份間隔的當天（如 2024 -> 2028 的 8 月 8 日）
            guard let lastCheck = lastCheckInDate else {
                // 如果從未打卡過，只要月日相符即可開始第一次
                return calendar.isDate(now, equalTo: targetDate, toGranularity: .month) &&
                       calendar.component(.day, from: targetDate) == calendar.component(.day, from: now)
            }
            let yearDiff = calendar.component(.year, from: now) - calendar.component(.year, from: lastCheck)
            let isCorrectYear = yearDiff > 0 && yearDiff % customIntervalYears == 0
            let isCorrectDay = calendar.isDate(now, equalTo: targetDate, toGranularity: .month) &&
                               calendar.component(.day, from: targetDate) == calendar.component(.day, from: now)
            return isCorrectYear && isCorrectDay
        }
    }
    
    /// 觸發打卡與連勝邏輯[cite: 8]
    func checkIn() {
        let calendar = Calendar.current
        let now = Date()
        
        // 判定是否屬於「連續的下一個週期」來增加連勝
        if let lastDate = lastCheckInDate {
            if isNextExpectedPeriod(from: lastDate) {
                streakCount += 1
            } else if !calendar.isDateInToday(lastDate) {
                streakCount = 1 // 錯過週期，斷開重開[cite: 8]
            }
        } else {
            streakCount = 1 // 首次打卡[cite: 8]
        }
        
        lastCheckInDate = now //[cite: 8]
        lastActionDate = now
        lastActionStatus = "completed"
        progress = 1.0 //[cite: 8]
    }
    
    /// 執行「略過一天/一期」，安全鎖定連勝數字不變[cite: 4]
    func skipCurrentPeriod() {
        let now = Date()
        lastActionDate = now
        lastActionStatus = "skipped"
        progress = 1.0 // 標記為今日已處理，防止斷連
        
        // 計算跳過截止時間到明天
        if let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now) {
            skipUntilDate = Calendar.current.startOfDay(for: tomorrow)
        }
    }
    
    /// 切換「暫停狀態」，完全凍結提醒與連勝
    func togglePause() {
        isPaused.toggle()
        if isPaused {
            progress = 0
        }
    }
    
    /// 精確計算是否為連續週期（包含前一次是略過的情境）
    private func isNextExpectedPeriod(from lastDate: Date) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        
        // 如果前一次操作是 skipped，或是今天已經打卡過，皆視為延續
        if calendar.isDateInToday(lastDate) || lastActionStatus == "skipped" {
            return true
        }
        
        switch recurrenceType {
        case .daily:
            return calendar.isDateInYesterday(lastDate)
            
        case .monthly:
            if let nextMonth = calendar.date(byAdding: .month, value: 1, to: lastDate) {
                return calendar.isDate(nextMonth, equalTo: now, toGranularity: .month)
            }
            return false
            
        case .yearly:
            if let nextYear = calendar.date(byAdding: .year, value: 1, to: lastDate) {
                return calendar.isDate(nextYear, equalTo: now, toGranularity: .year)
            }
            return false
            
        case .customYears:
            if let nextCustom = calendar.date(byAdding: .year, value: customIntervalYears, to: lastDate) {
                return calendar.isDate(nextCustom, equalTo: now, toGranularity: .year)
            }
            return false
        }
    }
}