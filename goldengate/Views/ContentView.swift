import SwiftUI

struct ContentView: View {
    @State private var selection: Int = 0
    
    var body: some View {
        TabView(selection: $selection) {
            Tab("Offers", systemImage: "receipt", value: 0) {
                OffersView()
                    .ignoresSafeArea(.all)
            }

            Tab("Account", systemImage: "person.crop.circle", value: 1) {
                AccountView()
                    .ignoresSafeArea(.all)
            }

            Tab("Revolut", systemImage: "wallet.bifold.fill", value: 2) {
                RevolutView()
                    .ignoresSafeArea(.all)
            }
        }
    }
}

#Preview {
    ContentView()
}
