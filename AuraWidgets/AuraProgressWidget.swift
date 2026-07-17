import WidgetKit
import SwiftUI

struct AuraEntry: TimelineEntry { let date: Date; let progress: Double }
struct AuraProvider: TimelineProvider {
    func placeholder(in context: Context) -> AuraEntry { AuraEntry(date: .now, progress: 0.67) }
    func getSnapshot(in context: Context, completion: @escaping (AuraEntry) -> Void) { completion(placeholder(in: context)) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<AuraEntry>) -> Void) { completion(Timeline(entries: [placeholder(in: context)], policy: .after(.now.addingTimeInterval(900)))) }
}
struct AuraProgressWidget: Widget {
    var body: some WidgetConfiguration { StaticConfiguration(kind: "AuraProgress", provider: AuraProvider()) { entry in
        ZStack { ContainerRelativeShape().fill(.black.gradient); VStack(alignment: .leading) { Text("AURA").font(.caption.weight(.bold)).foregroundStyle(.white.opacity(0.7)); Spacer(); Text("\(Int(entry.progress * 100))%").font(.system(size: 34, weight: .bold, design: .rounded)); Text("ritual energy").font(.caption).foregroundStyle(.cyan) }.padding() }.containerBackground(for: .widget) { Color.black }
    }.configurationDisplayName("Aura rituals").description("Today's liquid energy.").supportedFamilies([.systemSmall]) }
}
