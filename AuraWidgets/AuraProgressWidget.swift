import WidgetKit
import SwiftUI

struct AuraEntry: TimelineEntry { 
    let date: Date
    let progress: Double 
    let habitName: String // 新增：顯示當前充能的習慣名稱
}

struct AuraProvider: TimelineProvider {
    func placeholder(in context: Context) -> AuraEntry { 
        AuraEntry(date: .now, progress: 0.67, habitName: "流體充能") 
    }
    
    func getSnapshot(in context: Context, completion: @escaping (AuraEntry) -> Void) { 
        completion(placeholder(in: context)) 
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<AuraEntry>) -> Void) {
        // 免費帳號防禦性讀取：嘗試從群組解鎖的 UserDefaults 抓取主 App 寫入的最新進度
        let defaults = UserDefaults(suiteName: "group.com.aura.liquidglass") ?? UserDefaults.standard
        
        let progress = defaults.double(forKey: "currentHabitProgress") // 如果沒抓到預設會是 0.0
        let habitName = defaults.string(forKey: "currentHabitName") ?? "Aura 儀式"
        
        // 建立當前時間點的 entry
        let entry = AuraEntry(date: .now, progress: progress, habitName: habitName)
        
        // 設定每 15 分鐘重新整理一次 (900 秒)
        let timeline = Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(900)))
        completion(timeline)
    }
}

struct AuraProgressWidget: Widget {
    var body: some WidgetConfiguration { 
        StaticConfiguration(kind: "AuraProgress", provider: AuraProvider()) { entry in
            ZStack { 
                ContainerRelativeShape().fill(.black.gradient)
                VStack(alignment: .leading) { 
                    Text("AURA")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.7))
                    
                    Spacer()
                    
                    // 顯示動態讀取到的習慣名稱
                    Text(entry.habitName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(1)
                    
                    Text("\(Int(entry.progress * 100))%")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("ritual energy")
                        .font(.caption)
                        .foregroundStyle(.cyan) 
                }
                .padding() 
            }
            .containerBackground(for: .widget) { Color.black }
        }
        .configurationDisplayName("Aura rituals")
        .description("Today's liquid energy.")
        // 已修正：除了原本的 systemSmall，順便開啟 iOS 17+ 鎖定畫面小工具支援
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular]) 
    }
}