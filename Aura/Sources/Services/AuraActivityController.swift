import ActivityKit
import Foundation

@MainActor
final class AuraActivityController {
    static let shared = AuraActivityController()
    private var activity: Activity<AuraActivityAttributes>?
    private var lastUpdate = Date.distantPast

    /// ActivityKit updates are limited to four per second. SwiftUI animates
    /// between accepted snapshots in the widget to preserve a fluid display.
    func update(habitName: String, progress: Double, neonColorHex: String, isCharging: Bool) {
        guard !isCharging || Date.now.timeIntervalSince(lastUpdate) >= 0.25 else { return }
        lastUpdate = .now
        let state = AuraActivityAttributes.ContentState(habitName: habitName, currentProgress: progress, neonColorHex: neonColorHex)
        Task {
            if let activity {
                await activity.update(ActivityContent(state: state, staleDate: nil))
                if !isCharging { await activity.end(ActivityContent(state: state, staleDate: nil), dismissalPolicy: .immediate); self.activity = nil }
            }
            else if ActivityAuthorizationInfo().areActivitiesEnabled {
                activity = try? Activity.request(attributes: AuraActivityAttributes(activityID: UUID()), content: ActivityContent(state: state, staleDate: nil), pushType: nil)
            }
        }
    }
}
