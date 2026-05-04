import SwiftUI

struct AppCoordinator: View {
    @StateObject private var homeVM = HomeViewModel()

    var body: some View {
        NavigationStack {
            HomeView(viewModel: homeVM)
        }
    }
}
