import Foundation
import SwiftData

@Model
final class HabitModel {
    var id: UUID = UUID()
    var title: String = ""
    var progress: Double = 0
    var colorHex: String = "47D7FF"
    var iconName: String = "sparkles"

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
    }

    var isComplete: Bool { progress >= 1 }
}
