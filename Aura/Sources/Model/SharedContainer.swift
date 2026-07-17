import Foundation
import SwiftData

enum SharedContainer {
    static let appGroupIdentifier = "group.com.aura.liquidglass"
    static let cloudKitContainerIdentifier = "iCloud.com.aura.liquidglass"

    static let shared: ModelContainer = {
        let schema = Schema([HabitModel.self])

        let configuration: ModelConfiguration
        if let appGroupURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            // Full production build: App Group storage and private CloudKit sync.
            configuration = ModelConfiguration(
                "Aura",
                schema: schema,
                url: appGroupURL.appending(path: "Aura.store"),
                cloudKitDatabase: .private(cloudKitContainerIdentifier)
            )
        } else {
            // Free Apple ID / sideloaded builds cannot receive App Group or
            // CloudKit entitlements. Keep the app usable with an isolated,
            // on-device store instead of crashing at launch.
            configuration = ModelConfiguration(
                "AuraLocal",
                schema: schema,
                cloudKitDatabase: .none
            )
        }

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Unable to create shared ModelContainer: \(error)")
        }
    }()
}
