import Foundation
import SwiftData

enum SharedContainer {
    static let appGroupIdentifier = "group.com.aura.liquidglass"
    // 注意：免費帳號無法使用 CloudKit，上機時會自動走 else 降級邏輯
    static let cloudKitContainerIdentifier = "iCloud.com.aura.liquidglass"

    // 用於持久化儲存自訂背景照片的資料鍵值
    private static let customBackgroundKey = "aura_custom_background_data"

    /// 安全動態獲取 UserDefaults（防禦免費帳號無法載入 Suite 的狀況）
    private static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupIdentifier) ?? UserDefaults.standard
    }

    /// 讀取目前儲存的自訂背景相片（已修正：改用群組級別的 UserDefaults 以便小工具讀取）
    static var customBackgroundData: Data? {
        get {
            sharedDefaults.data(forKey: customBackgroundKey)
        }
        set {
            sharedDefaults.set(newValue, forKey: customBackgroundKey)
        }
    }

    static let shared: ModelContainer = {
        let schema = Schema([HabitModel.self])

        let configuration: ModelConfiguration
        
        // 檢查 1：確認 App Group 是否可用
        // 檢查 2：檢查當前描述檔是否包含 CloudKit 權限（動態防止免費帳號 Sideload 閃退）
        if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier),
           hasCloudKitEntitlement() {
            
            configuration = ModelConfiguration(
                "Aura",
                schema: schema,
                url: appGroupURL.appending(path: "Aura.store"),
                cloudKitDatabase: .private(cloudKitContainerIdentifier)
            )
        } else if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            // 免費帳號最常走的路線：有本地 App Group 沙盒，但「沒有」 CloudKit 權限
            configuration = ModelConfiguration(
                "AuraGroupLocal",
                schema: schema,
                url: appGroupURL.appending(path: "Aura.store"),
                cloudKitDatabase: .none // 關閉 CloudKit，防止免費帳號特徵閃退
            )
        } else {
            // 終極降級方案：雙方皆無權限，走本機獨立沙盒
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
    
    /// 動態偵測當前 App 是否具備 iCloud (CloudKit) 權限
    private static func hasCloudKitEntitlement() -> Bool {
        // 免費帳號的 Token 通常不包含 iCloud 容器權限，藉此動態隔離
        return FileManager.default.ubiquityIdentityToken != nil
    }
}