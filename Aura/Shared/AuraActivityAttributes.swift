import ActivityKit
import Foundation

/// Keep this type in both the app and widget-extension targets.
struct AuraActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var habitName: String
        var currentProgress: Double
        var neonColorHex: String
    }

    var activityID: UUID
}
