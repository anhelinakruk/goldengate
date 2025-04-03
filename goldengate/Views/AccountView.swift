import SwiftUI
import ReownAppKit
import Foundation
import Combine
import WalletConnectSign


struct AccountView: View {
    @State private var privateResponse: String = ""
    @State private var publicResponse: String = ""
    
    var body : some View {
        AppKitButton()
        Button(action: {
            sendRequest(to: "http://localhost:3000/private") { response in
                privateResponse = response
            }
        }) {
            Text("Send Private Request")
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
        
        Text("Private Response: \(privateResponse)")
            .padding()
        
        Button(action: {
            sendRequest(to: "http://localhost:3000/public") { response in
                publicResponse = response
            }
        }) {
            Text("Send Public Request")
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
        
        Text("Public Response: \(publicResponse)")
            .padding()
    }
}

func sendRequest(to urlString: String, completion: @escaping (String) -> Void) {
    guard let url = URL(string: urlString) else {
        completion("Invalid URL")
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            completion(error.localizedDescription)
        }
        
        if let data = data, let responseString = String(data: data, encoding: .utf8) {
            completion(responseString)
        } else {
            completion("No Data recieved")
        }
    }.resume()
}

class SocketConnectionManager: ObservableObject {
    @Published var socketConnected: Bool = false
}

@MainActor
class AccountViewModel: ObservableObject {
    var disposeBag = Set<AnyCancellable>()
    var socketConnectionManager = SocketConnectionManager()
    @Published var alertMessage: String = ""
    @Published var nonce: String? = nil
    init() {
        setup()
    }
        
        private func setup() {
            Networking.configure(
                groupIdentifier: "group.com.walletconnect.web3modal",
                projectId: "a482c487e774191d71e6a066b17c9f57",
                socketFactory: DefaultSocketFactory()
            )
            
            Task {
                do {
                    let fetchedNonce = try await getNonce()
                    self.nonce = fetchedNonce
                    print("Received nonce: \(fetchedNonce)")
                    
                    await configureAppKit(with: fetchedNonce)
                } catch {
                    DispatchQueue.main.async {
                        self.alertMessage = "Error fetching nonce: \(error.localizedDescription)"
                    }
                }
            }
        }
        
        private func configureAppKit(with nonce: String) async {
            let projectId = "a482c487e774191d71e6a066b17c9f57"
            
            let metadata = AppMetadata(
                name: "Example Wallet",
                description: "Wallet description",
                url: "example.wallet",
                icons: ["https://avatars.githubusercontent.com/u/37784886"],
                redirect: try! .init(native: "w3mdapp://", universal: "https://lab.web3modal.com/web3modal_example", linkMode: true)
            )
            
            AppKit.configure(
                projectId: projectId,
                metadata: metadata,
                crypto: DefaultCryptoProvider(),
                authRequestParams: .stub(nonce: nonce),
                includedWalletIds: ["4622a2b2d6af1c9844944291e5e7351a6aa24cd7b23099efac1b2fd875da31a0"],
                coinbaseEnabled: false
            ) { error in
                print("Error during AppKit configuration: \(String(describing: error))")
            }
            
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
                        
                        Task {
                            do {
                                let messageString = try await self?.prepareMessage(cacaos: cacaos)
                                print("Message String: \(String(describing: messageString))")
                                if let firstCacao = cacaos.first {
                                    let signature = firstCacao.s.s
                                    let iss = firstCacao.p.iss
                                    let parts = iss.split(separator: ":")
                                    if parts.count >= 4 {
                                        let address =  String(parts[4])
                                        try await self?.sendMessageToServer(message: messageString ?? "", signature: signature, address:    address)
                                    }
                                }
                            } catch {
                                print("Error while preparing message: \(error)")
                            }
                        }
                    case .failure(let error):
                        print("User authentication error: \(error)")
                    }
                }
                .store(in: &disposeBag)
        }
    
    public func prepareMessage(cacaos: [Cacao]) async throws -> String {
        let messageFormatter = SIWEFromCacaoPayloadFormatter()
        var messageString = ""
        
        try await cacaos.asyncForEach { cacao in
            guard
                let message = try? messageFormatter.formatMessage(from: cacao.p, includeRecapInTheStatement: true)
            else {
                throw AuthError.malformedResponseParams
            }
            
            messageString = message
        }
        
        return messageString
    }
    
    func getNonce() async throws -> String {
        guard let url = URL(string: "http://localhost:3000/auth") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            print("Reponse: \(response)")
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw NSError(domain: "NetworkingError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid server response"])
            }
            
            let decoder = JSONDecoder()
            let nonceResponse = try decoder.decode(NonceResponse.self, from: data)
            
            return nonceResponse.message
        } catch {
            throw error
        }
    }
    
    @MainActor
    public func sendMessageToServer(message: String, signature: String, address: String) async throws {
        guard let url = URL(string: "http://localhost:3000/auth") else {
            DispatchQueue.main.async {
                self.alertMessage = "Invalid URL"
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue( "application/json", forHTTPHeaderField: "Content-Type")
        
        let jsonBody: [String: Any] = ["message": message, "signature": signature, "address": address]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonBody, options: [])
            request.httpBody = jsonData
            
            let (data, response) = try await URLSession.shared.data(for: request)
            print("Data send message \(data)")
            print("Response \(response)")
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                if let responseMessage = String(data: data, encoding: .utf8) {
                    print("Server response: \(responseMessage)")
                    
                    // Dekodowanie odpowiedzi JSON
                    let decoder = JSONDecoder()
                    do {
                        let responseObject = try decoder.decode(ResponseMessage.self, from: data)
                        print("Token: \(responseObject.access_token)")
                        
                    } catch {
                        DispatchQueue.main.async {
                            self.alertMessage = "Error decoding response: \(error.localizedDescription)"
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.alertMessage = "Failed to send message"
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.alertMessage = "Error: \(error.localizedDescription)"
            }

        }
    }
}
