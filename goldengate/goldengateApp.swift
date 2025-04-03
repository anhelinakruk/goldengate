import SwiftUI
import ReownAppKit

@main
struct goldengateApp: App {
    @StateObject private var viewModel = AccountViewModel()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    AppKit.instance.handleDeeplink(url)
                }
                .alert(
                    "Response",
                    isPresented: Binding(
                        get: {!viewModel.alertMessage.isEmpty},
                        set: {_ in viewModel.alertMessage = ""}
                    )
                ) {
                    Button("Dismiss", role: .cancel) {}
                } message: {
                    Text(viewModel.alertMessage)
                }
        }
    }
}
