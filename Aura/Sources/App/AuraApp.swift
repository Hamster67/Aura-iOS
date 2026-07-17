import SwiftUI
import SwiftData

@main
struct AuraApp: App {
    private let modelContainer = SharedContainer.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
