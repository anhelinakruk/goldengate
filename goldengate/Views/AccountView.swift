import SwiftUI
import metamask_ios_sdk
import BigInt

struct AccountView: View {
    @State private var privateResponse: String = ""
    private var appURL: String = "http://goldengate.visoft.dev"
    
    @State private var USDTAddress: String = "0x9D16475f4d36dD8FC5fE41F74c9F44c7EcCd0709"
    
    @State private var depositAmount: String = ""
    @State private var withdrawAmount: String = ""
    @State private var withdrawAddress: String = ""
    @State private var chainID = ""
    @State private var messageSigned = false
    @State private var errorMessage = ""
    @State private var showError = false
    
    @State private var balance: Double = 0.0
    
    @FocusState private var focusedField: Field?
    enum Field {
            case depositAmount
            case withdrawAmount
            case withdrawAddress
    }
    
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
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // MARK: - Metamask Info Section
                    VStack(spacing: 10) {
                        infoRow(label: "Status", value: status)
                        infoRow(label: "Chain ID", value: metaMaskSDK.chainId)
                        infoRow(label: "Account", value: shortenAddress(metaMaskSDK.account))
                        infoRow(label: "Balance", value: "\(balance)")
                        infoRow(label: "Message Signed", value: messageSigned.description)
                        infoRow(label: "Error:", value: errorMessage)
                    }
                    .padding()
                    .background(Color(.systemGroupedBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    .padding(.horizontal)

                    // MARK: - Buttons
                    VStack(spacing: 12) {
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
                    }
                    .padding(.horizontal)

                    // MARK: - Deposit Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Enter amount to deposit:")
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                            Spacer()
                        }

                        TextField("Enter amount", text: $depositAmount)
                            .numbersOnly($depositAmount, maxDecimalPlaces: 6)
                            .padding(10)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .shadow(radius: 3)
                            .focused($focusedField, equals: .depositAmount)

                        Button {
                            Task {
                                await deposit(amount: $depositAmount.wrappedValue, address: metaMaskSDK.account)
                            }
                        } label: {
                            Text("Deposit")
                                .frame(maxWidth: .infinity, maxHeight: 32)
                        }
                    }
                    .padding()
                    .background(Color(.systemGroupedBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    .padding(.horizontal)

                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Enter amount to withdraw:")
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                            Spacer()
                            TextField("Enter amount", text: $withdrawAmount)
                                .numbersOnly($depositAmount, maxDecimalPlaces: 6)
                                .padding(10)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                                .shadow(radius: 3)
                                .focused($focusedField, equals: .withdrawAmount)
                        }
                        
                        HStack {
                            Text("Address to withdraw:")
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                            Spacer()
                            TextField("Enter adress '0x...'", text: $withdrawAddress)
                                .padding(10)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                                .shadow(radius: 3)
                                .focused($focusedField, equals: .withdrawAddress)
                        }


                        Button {
                            Task {
                                await withdraw(amount: $withdrawAmount.wrappedValue, address: $withdrawAddress.wrappedValue)
                            }
                        } label: {
                            Text("Withdraw")
                                .frame(maxWidth: .infinity, maxHeight: 32)
                        }
                    }
                    .padding()
                    .background(Color(.systemGroupedBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    .padding(.horizontal)

                }
            }
            .navigationTitle("Metamask")
            .alert(isPresented: $showError) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage)
                )
            }
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    Spacer()
                }
                ToolbarItem(placement: .keyboard) {
                    Button {
                        focusedField = nil
                    } label: {
                        Image(systemName: "keyboard.chevron.compact.down")
                    }
                }
            }
        }
    }

    // Helper View for info rows
    @ViewBuilder
    func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .bold()
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
    }

    func deposit(amount: String, address: String) async {
        print("Depositing amount: \(amount) to \(address)")
        
        guard let amountDouble = Double(amount.replacingOccurrences(of: ",", with: "."))  else {
            self.errorMessage = "Failed to parse amount to double"
            return
        }
        
        let encodedCallData = encodeCallData(to: "0xD48592C606533078CB37Eee94f9471f68cfBefE2", value: amountDouble)
        print("Encoded data: \(encodedCallData)")
        
        let transaction = Transaction(
            to: USDTAddress,
            from: address,
            value: "0x0",
            data: encodedCallData
        )
        
        let parameters: [Transaction] = [transaction]
        let transactionRequest = EthereumRequest(
            method: .ethSendTransaction,
            params: parameters
        )
        let sign = await metaMaskSDK.request(
            transactionRequest
        )
        
        print("Sign \(sign)")
        
        switch sign {
            case let .success(value):
                print("Signed: \(value)")
            let amountToDeposit = Int(amountDouble * pow(10, 6))
            confirmDeposit(txhash: value, amount: amountToDeposit)
        case let .failure(error):
            print("Error: \(error)")
        }
        print("Sign: \(sign)")
    }
    
    func confirmDeposit(txhash: String, amount: Int) {
        guard let url = URL(string: "http://192.168.1.101:3000/private/deposit") else {
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
        
        print("Hello before connectAndSign")
        let connect = await metaMaskSDK.connect()
        
        print("connect Result: \(connect)")
        
        switch connect {
        case let .success(value):
            print("Sign a message")
            status = "Connected"
            errorMessage = ""
        case let .failure(error):
            print("Hmm")
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func signMessage(message: SIWEMessage, address: String) async {
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
        guard let url = URL(string: "http://192.168.1.101:3000/auth") else {
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
        guard let url = URL(string: "http://192.168.1.101:3000/auth") else {
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
    
    func encodeCallData(to: String, value: Double) -> String {
        let methodID = "a9059cbb"
        
        let addressWithoutPrefix = String(to.dropFirst(2).lowercased())
        let paddedToAddress = addressWithoutPrefix.leftPadding(toLength: 64, withPad: "0")
        print("paddded address: \(paddedToAddress)")
        
        let u256Value = BigInt(value * pow(10.0, Double(18)))
        print("U256 \(u256Value)")

        let hexValue = String(u256Value, radix: 16)
        let paddedValue = hexValue.leftPadding(toLength: 64, withPad: "0")
        
        print("padded value: \(paddedValue)")
        
        let transactionData = "0x" + methodID + paddedToAddress + paddedValue
        
        return transactionData
    }
    
    func withdraw(amount: String, address: String) {
        guard let url = URL(string: "http://192.168.1.101:3000/private/withdraw") else {
            self.errorMessage = "Invalid URL"
            return
        }
        
        print("Withdrawwing")
        
        guard let amountDouble = Double(amount) else {
            self.errorMessage = "Invalid amount"
            return
        }
        
        let amountU6 = Int(amountDouble * pow(10, 6))
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue( "application/json", forHTTPHeaderField: "Content-Type")
        
        let withdraw = withdrawRequest(amount: amountU6, address: address)
        
        print("Withdraw: \(withdraw)")
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(withdraw)
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
                    print("Withdraw succesfull")
                    do {
                        let decoder = JSONDecoder()
                        let depositResponse = try decoder.decode(confirmDepositResponse.self, from: data)
                            
                        balance = Double(depositResponse.balance) / pow(10, 6)
                    } catch {
                        print("Error decoding response: \(error.localizedDescription)")
                    }
                } else {
                    self.errorMessage = "Failed to withdraw"
                }
            }.resume()
        } catch {
            self.errorMessage = error.localizedDescription
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

extension String {
    func leftPadding(toLength: Int, withPad character: Character) -> String {
        if self.count >= toLength { return self }
        return String(repeatElement(character, count: toLength - self.count)) + self
    }
}
