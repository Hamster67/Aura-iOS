import Foundation
import SwiftData

enum SharedContainer {
    static let appGroupIdentifier = "group.com.aura.liquidglass"
    static let cloudKitContainerIdentifier = "iCloud.com.aura.liquidglass"

    // 用於持久化儲存自訂背景照片的資料鍵值
    private static let customBackgroundKey = "aura_custom_background_data"

    /// 讀取目前儲存的自訂背景相片
    static var customBackgroundData: Data? {
        get {
            UserDefaults.standard.data(forKey: customBackgroundKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: customBackgroundKey)
        }
    }

    static let shared: ModelContainer = {
        let schema = Schema([HabitModel.self])

        let configuration: ModelConfiguration
        if let appGroupURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            configuration = ModelConfiguration(
                "Aura",
                schema: schema,
                url: appGroupURL.appending(path: "Aura.store"),
                cloudKitDatabase: .private(cloudKitContainerIdentifier)
            )
        } else {
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