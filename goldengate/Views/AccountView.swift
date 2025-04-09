import SwiftUI
import metamask_ios_sdk

struct AccountView: View {
    @State private var privateResponse: String = ""
    @State private var publicResponse: String = ""
    
    private var appURL: String = "http://goldengate.visoft.dev"
    
    @State private var USDTAddress: String = "0x9D16475f4d36dD8FC5fE41F74c9F44c7EcCd0709"
    
    @State private var showProgressView = false
    @State private var depositAmoount: String = ""
    @State private var chainID = ""
    @State private var address: String = ""
    @State private var messageSigned = false
    @State private var errorMessage = ""
    @State private var showError = false
    
    @State private var balance: Double = 0.0
    
    @State private var metaMaskSDK = MetaMaskSDK.shared(
        AppMetadata(
            name: "Example Wallet Metamask",
            url:  "https://goldengate.visoft.dev"),
        transport: .socket,
        sdkOptions: nil
    )
    
    @State private var status: String = "Offline"

    var body: some View {
        NavigationView {
            List {
                Section {
                    Group {
                        HStack {
                            Text("Status")
                                .bold()
                            Spacer()
                            Text(status)
                        }
                        
                        HStack {
                            Text("Chain ID")
                                .bold()
                            Spacer()
                            Text(metaMaskSDK.chainId)
                        }
                        
                        HStack {
                            Text("Account")
                                .bold()
                            Spacer()
                            Text(shortenAddress(metaMaskSDK.account))
                        }
                        
                        HStack {
                            Text("Balance")
                                .bold()
                            Spacer()
                            Text("\(balance)")
                        }
                        
                        HStack {
                            Text("Message Signed")
                                .bold()
                            Spacer()
                            Text(messageSigned.description)
                        }
                        
                        HStack {
                            Text("Error:")
                                .bold()
                            Spacer()
                            Text(errorMessage)
                        }
                    }
                }
                
            }
            
            if showProgressView {
                ProgressView()
                    .scaleEffect(1.5, anchor: .center)
                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
            }
            
        }
        .alert(isPresented: $showError) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage)
            )
        }
        
        
        Button {
            Task {
                await connectMetamask()
            }
        } label: {
            Text("Connect Metamask")
                .frame(maxWidth: .infinity, maxHeight: 32)
        }
        
        Button {
            Task {
                await disconnectSDK()
            }
        } label: {
            Text("Disconnect")
                .frame(maxWidth: .infinity, maxHeight: 32)
        }
        
        Button {
            Task {
                let currentDate = Date()
                let isoFormatter = ISO8601DateFormatter()
                
                do {
                    let fetchedNonce = try await getNonce()
                    print("Received nonce: \(fetchedNonce)")
                
                    let siweMessage = SIWEMessage(
                        address: metaMaskSDK.account,
                        uri: appURL,
                        version: 1,
                        chainId: 1,
                        nonce: fetchedNonce,
                        issuedAt: isoFormatter.string(from: currentDate)
                    )
                    
                    await signMessage(message: siweMessage, address: metaMaskSDK.account)
                } catch {
                    self.errorMessage = "Error fetching nonce: \(error.localizedDescription)"
                }
                
            }
        } label: {
            Text("Sign Message")
                .frame(maxWidth: .infinity, maxHeight: 32)
        }
        
        VStack {
            HStack {
                Text("Enter amount to deposit:")
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                Spacer()
                TextField("Enter amount", text: $depositAmoount)
                    .padding(10)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .shadow(radius: 3)
            }
            .padding(.bottom, 15)
            Button {
                Task {
                    await deposit(amount: $depositAmoount.wrappedValue, address: address)
                }
            } label: {
                Text("Deposit")
                    .frame(maxWidth: .infinity, maxHeight: 32)
            }
        }
        
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
    
    func deposit(amount: String, address: String) async {
        print("Depositing amount: \(amount) to \(address)")
        
        guard let amountDouble = Double(amount.replacingOccurrences(of: ",", with: "."))  else {
            self.errorMessage = "Failed to parse amount to double"
            return
        }

        let amountToDeposit = Int(amountDouble * pow(10, 6))
        
        let transaction = Transaction(
            to: USDTAddress,
            from: address,
            value: "0x0",
            data: "0xa9059cbb000000000000000000000000d48592c606533078cb37eee94f9471f68cfbefe2000000000000000000000000000000000000000000000000002386f26fc10000"
        )
        
        let parameters: [Transaction] = [transaction]
        let transactionRequest = EthereumRequest(
            method: .ethSendTransaction,
            params: parameters
        )
        let sign = await metaMaskSDK.request(
            transactionRequest
        )
        
        print("Signe \(sign)")
        
        switch sign {
            case let .success(value):
                print("Signed: \(value)")
            confirmDeposit(txhash: value, amount: amountToDeposit)
        case let .failure(error):
            print("Error: \(error)")
        }
        print("Sign: \(sign)")
    }
    
    func confirmDeposit(txhash: String, amount: Int) {
        guard let url = URL(string: "http://localhost:3000/private/deposit") else {
            self.errorMessage = "Invalid URL"
            return
        }
        
        print("Confirming")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue( "application/json", forHTTPHeaderField: "Content-Type")
        
        let deposit = confirmDepositRequest(txHash: txhash, amount: amount)
        
        print("Deposit: \(deposit)")
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(deposit)
            request.httpBody = data
            
            let config = URLSessionConfiguration.default
                    config.timeoutIntervalForRequest = 200.0
                    config.timeoutIntervalForResource = 250.0

                    let session = URLSession(configuration: config)
            
            session.dataTask(with: request) { data, response, error in
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                guard let data = data else {
                    print("No data received")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    print("Deposit succesfull")
                    do {
                        let decoder = JSONDecoder()
                        let depositResponse = try decoder.decode(confirmDepositResponse.self, from: data)
                            
                        balance = Double(depositResponse.balance) / pow(10, 6)
                    } catch {
                        print("Error decoding response: \(error.localizedDescription)")
                    }
                } else {
                    self.errorMessage = "Failed to deposit"
                }
            }.resume()
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
    }
    
    func connectMetamask() async {
        await disconnectSDK()
        showProgressView = true
        
        print("Hello before connectAndSign")
        let connect = await metaMaskSDK.connect()
        
        print("connect Result: \(connect)")

        showProgressView = false
        
        switch connect {
        case let .success(value):
            print("Sign a message")
            address = value.first!
            status = "Connected"
            errorMessage = ""
        case let .failure(error):
            print("Hmm")
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func signMessage(message: SIWEMessage, address: String) async {
        showProgressView = true
        let siweString =
"""
Goldendate wants you to sign in with your Ethereum account:
\(message.address)

Goldendate

URI: \(message.uri)
Version: \(message.version)
Chain ID: \(message.chainId)
Nonce: \(message.nonce)
Issued At: \(message.issuedAt)
"""
        let signRequest = await metaMaskSDK.personalSign(message: siweString, address: address)
        print("Sign Request: \(signRequest)")
        showProgressView = false
        
        switch signRequest {
        case let .success(signature):
            print("signature: \(signature)")
            do {
                try await sendMessageToServer(message: siweString, signature: signature, address: address)
                status = "Signed"
                messageSigned = true
            } catch {
                self.errorMessage = error.localizedDescription
                showError = true
            }
        case let .failure(error):
            errorMessage = error.localizedDescription
            showError = true
        }
        
    }
        
        func shortenAddress(_ address: String) -> String {
            guard address.count > 8 else { return address }
            let start = address.prefix(4)
            let end = address.suffix(4)
            return "\(start)...\(end)"
        }
        
        func disconnectSDK() async {
            print("Disconnecting from MetaMask...")
            metaMaskSDK.clearSession()
            metaMaskSDK.terminateConnection()
            status = "Offline"
        }
    
    
    public func sendMessageToServer(message: String, signature: String, address: String) async throws {
        guard let url = URL(string: "http://localhost:3000/auth") else {
            self.errorMessage = "Invalid URL"
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

                    let decoder = JSONDecoder()
                    do {
                        let responseObject = try decoder.decode(ResponseMessage.self, from: data)
                        print("Token: \(responseObject.access_token)")
                        
                    } catch {
                        self.errorMessage = "Error decoding response: \(error.localizedDescription)"
                    }
                }
            } else {
                self.errorMessage = "Failed to send message"
            }
        } catch {
                self.errorMessage = "Error: \(error.localizedDescription)"
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
    
    struct SIWEMessage: Codable {
        let address: String
        let uri: String
        let version: Int32
        let chainId: Int32
        let nonce: String
        let issuedAt: String
    }
    
    struct Transaction: CodableData {
        let to: String
        let from: String
        let value: String
        let data: String?

        init(to: String, from: String, value: String, data: String? = nil) {
            self.to = to
            self.from = from
            self.value = value
            self.data = data
        }

        func socketRepresentation() -> NetworkData {
            [
                "to": to,
                "from": from,
                "value": value,
                "data": data
            ]
        }
    }
}
