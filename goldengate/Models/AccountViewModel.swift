import SwiftUI
import Combine
import ReownAppKit
import WalletConnectSign

#if DEBUG
import Atlantis
#endif

class SocketConnectionManager: ObservableObject {
    @Published var socketConnected: Bool = false
}

class AccountViewModel: ObservableObject {
    var disposeBag = Set<AnyCancellable>()
    var socketConnectionManager = SocketConnectionManager()
    @Published var alertMessage: String = ""
    
    init() {
#if DEBUG
        Atlantis.start()
#endif
        
        let projectId = "a482c487e774191d71e6a066b17c9f57"
        
        let metadata = AppMetadata(
            name: "Example Wallet",
            description: "Wallet description",
            url: "example.wallet",
            icons: ["https://avatars.githubusercontent.com/u/37784886"],
            redirect: try! .init(native: "w3mdapp://", universal: "https://lab.web3modal.com/web3modal_example", linkMode: true)
        )
        
        Networking.configure(
            groupIdentifier: "group.com.walletconnect.web3modal",
            projectId: projectId,
            socketFactory: DefaultSocketFactory()
        )
        
        AppKit.configure(
            projectId: projectId,
            metadata: metadata,
            crypto: DefaultCryptoProvider(),
            authRequestParams: .stub(),
            includedWalletIds: ["4622a2b2d6af1c9844944291e5e7351a6aa24cd7b23099efac1b2fd875da31a0"],
            coinbaseEnabled: false
        ) { error in
            print(error)
        }
        
        setup()
    }
    
    private func setup() {
        AppKit.instance.socketConnectionStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                print("Socket connection status: \(status)")
                self?.socketConnectionManager.socketConnected = (status == .connected)
            }
            .store(in: &disposeBag)

        AppKit.instance.logger.setLogging(level: .debug)
        Sign.instance.setLogging(level: .debug)
        Networking.instance.setLogging(level: .debug)
        Relay.instance.setLogging(level: .debug)
        
        AppKit.instance.authResponsePublisher
            .sink { [weak self] (id: RPCID, result: Result<(Session?, [Cacao]), AuthError>) in
                switch result {
                case .success((_, let cacaos)):
                    print("User authenticated result: \(result)")
                    
                    // Wyciąganie pierwszego Cacao z odpowiedzi
                    if let firstCacao = cacaos.first {
                        // Wyciąganie podpisu
                        let signature = firstCacao.s.s
                        print("Podpis: \(signature)")
                        
                        // Wyciąganie wiadomości
                        let message = firstCacao.p.statement ?? ""
                        print("Wiadomość: \(message)")
                        
                        // Wyciąganie adresu użytkownika (publiczny klucz)
//                        let address = firstCacao.p.iss
                        let address = "0x508230e512CCb42cE66417Db21Cdd962212B4735"
                        print("Address: \(address)")
                        
                        // Możesz używać standardowego Ethereum chainId: "1" dla głównej sieci Ethereum
                        let chainId = "eip155:1" // Ethereum mainnet
                        
                        // Verifying the SIWE message
                        self?.verifySIWE(signature: signature, message: message, address: address, chainId: chainId)
                    }
                case .failure(let error):
                    print("User authentication error: \(error)")
                }
            }
            .store(in: &disposeBag)

    }
    
    func verifySIWE(signature: String, message: String, address: String, chainId: String) {
        Task {
            do {
                // Wywołanie metody do weryfikacji podpisu SIWE
                try await Sign.instance.verifySIWE(
                    signature: signature,
                    message: message,
                    address: address,
                    chainId: chainId
                )
                print("Podpis SIWE jest prawidłowy!")
                // Możesz przejść do kolejnych kroków, np. autoryzować użytkownika lub uzyskać dostęp do zasobów
            } catch {
                print("Błąd podczas weryfikacji SIWE: \(error)")
                // Obsłuż błąd weryfikacji, np. wyświetl komunikat użytkownikowi
            }
        }
    }

}

//@main
//struct walletExampleApp: App {
//    @StateObject private var viewModel = AccountViewModel()
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//                .onOpenURL { url in
//                    AppKit.instance.handleDeeplink(url)
//                }
//                .alert(
//                    "Response",
//                    isPresented: Binding(
//                        get: {!viewModel.alertMessage.isEmpty},
//                        set: {_ in viewModel.alertMessage = ""}
//                    )
//                ) {
//                    Button("Dismiss", role: .cancel) {}
//                } message: {
//                    Text(viewModel.alertMessage)
//                }
//                .onReceive(AppKit.instance.sessionResponsePublisher) {
//                    response in
//                    switch response.result {
//                    case let .response(value):
//                        viewModel.alertMessage = "\(value)"
//                    case let .error(error):
//                        viewModel.alertMessage = "\(error)"
//                    }
//                }
//            
//        }
//    }
//}


extension AuthRequestParams {
    static func stub(
        domain: String = "lab.web3modal.com",
        chains: [String] = ["eip155:1"],
        nonce: String = "32891756",
        uri: String = "https://lab.web3modal.com",
        nbf: String? = nil,
        exp: String? = nil,
        statement: String? = "I accept the ServiceOrg Terms of Service: https://lab.web3modal.com",
        requestId: String? = nil,
        resources: [String]? = nil,
        methods: [String]? = ["personal_sign", "eth_sendTransaction"]
    ) -> AuthRequestParams {
        return try! AuthRequestParams(
            domain: domain,
            chains: chains,
            nonce: nonce,
            uri: uri,
            nbf: nbf,
            exp: exp,
            statement: statement,
            requestId: requestId,
            resources: resources,
            methods: methods
        )
    }
}


