import Foundation
import SwiftData

enum SharedContainer {
    static let appGroupIdentifier = "group.com.aura.liquidglass"
    static let cloudKitContainerIdentifier = "iCloud.com.aura.liquidglass"

    static let shared: ModelContainer = {
        let schema = Schema([HabitModel.self])

        guard let appGroupURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
        else {
            fatalError("Unable to access App Group: \(appGroupIdentifier)")
        }

        let configuration = ModelConfiguration(
            "Aura",
            schema: schema,
            url: appGroupURL.appending(path: "Aura.store"),
            cloudKitDatabase: .private(cloudKitContainerIdentifier)
        )

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Unable to create shared ModelContainer: \(error)")
        }
    }()
}
