import SwiftUI

final class UserModel: ObservableObject {
    @Published var status: String = "Offline"
    @Published var balance: Double = 0.0
}

struct ContentView: View {
    @State private var selection: Int = 0
    
    @StateObject var userModel = UserModel()
    
    var body: some View {
        TabView(selection: $selection) {
            Tab("Offers", systemImage: "receipt", value: 0) {
                OffersView()
                    .ignoresSafeArea(.all)
                    .environmentObject(userModel)
            }

            Tab("Account", systemImage: "person.crop.circle", value: 1) {
                AccountView()
                    .ignoresSafeArea(.all)
                    .environmentObject(userModel)
            }

            Tab("Revolut", systemImage: "wallet.bifold.fill", value: 2) {
                RevolutView()
                    .ignoresSafeArea(.all)
            }
        }
    }
}

