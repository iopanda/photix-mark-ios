import SwiftUI

@main
struct PhotixMarkApp: App {
    init() {
        ProcessorRegistry.shared.registerAll()
    }

    var body: some Scene {
        WindowGroup {
            AppCoordinator()
        }
    }
}
