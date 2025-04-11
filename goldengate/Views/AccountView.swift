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
    
    @State private var alertMessage = ""
    @State private var showAlert = false
    
    @State private var depositAddress = ""

    
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
    
    @EnvironmentObject var userModel: UserModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    
                    // MARK: - Metamask Info Section
                    VStack(spacing: 0) {
                        infoRow(label: "Status", value: userModel.status)
                        Divider()
                        infoRow(label: "Chain ID", value: metaMaskSDK.chainId)
                        Divider()
                        infoRow(label: "Account", value: shortenAddress(metaMaskSDK.account))
                        Divider()
                        infoRow(label: "Balance", value: "\(userModel.balance)")
                        Divider()
                        infoRow(label: "Message Signed", value: messageSigned.description)
                        Divider()
                        
                        if userModel.status == "Signed" {
                            NavigationLink(destination: UserOfferView().environmentObject(userModel)) {
                                HStack {
                                    Text("View my offers")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                            }
                        } else {
                            Button {
                                alertMessage = "You need to sign message to view your offers."
                                showAlert = true
                            } label: {
                                HStack {
                                    Text("View my offers")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                            }
                        }
                    }

                    // MARK: - Buttons
                    HStack(spacing: 12) {
                        if userModel.status ==  "Offline" {
                            Button {
                                Task {
                                    await connectMetamask()
                                }
                            } label: {
                                Text("Connect Metamask")
                            }
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .foregroundColor(.white)
                            .background(Color.blue)
                            .cornerRadius(12)
                            .shadow(radius: 5)
                        } else {
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
                                        self.alertMessage = "Error fetching nonce: \(error.localizedDescription)"
                                        self.showAlert = true
                                    }
                                }
                            } label: {
                                Text("Sign Message")
                            }
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .foregroundColor(.white)
                            .background(Color.green)
                            .cornerRadius(12)
                            .shadow(radius: 5)
                            Button {
                                Task {
                                    await disconnectSDK()
                                }
                            } label: {
                                Text("Disconnect")
                            }
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .foregroundColor(.white)
                            .background(Color.red)
                            .cornerRadius(12)
                            .shadow(radius: 5)
                        }
                    }
                    .padding(.horizontal)

                    // MARK: - Deposit Section
                    if messageSigned {
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
                            }
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .foregroundColor(.white)
                            .background(Color.blue)
                            .cornerRadius(12)
                            .shadow(radius: 5)
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
                            }
                            TextField("Enter amount", text: $withdrawAmount)
                                .numbersOnly($depositAmount, maxDecimalPlaces: 6)
                                .padding(10)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                                .shadow(radius: 3)
                                .focused($focusedField, equals: .withdrawAmount)
                            
                            HStack {
                                Text("Address to withdraw:")
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                                Spacer()
                            }
                            TextField("Enter adress '0x...'", text: $withdrawAddress)
                                .padding(10)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                                .shadow(radius: 3)
                                .focused($focusedField, equals: .withdrawAddress)
                            
                            
                            Button {
                                Task {
                                    await withdraw(amount: $withdrawAmount.wrappedValue, address: $withdrawAddress.wrappedValue)
                                }
                            } label: {
                                Text("Withdraw")
                            }
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .foregroundColor(.white)
                            .background(Color.blue)
                            .cornerRadius(12)
                            .shadow(radius: 5)
                        }
                        .padding()
                        .background(Color(.systemGroupedBackground))
                        .cornerRadius(12)
                        .shadow(radius: 2)
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Your account")
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Alert"),
                    message: Text(alertMessage)
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
        .environmentObject(userModel)
        .onAppear {
            if !metaMaskSDK.account.isEmpty {
                userModel.status = "Connected"
                if messageSigned {
                    userModel.status = "Signed"
                }
            } else {
                metaMaskSDK.clearSession()
            }
            
            Task {
                    if let fetchedBalance = await getBalance() {
                        userModel.balance = fetchedBalance
                    } else {
                        userModel.balance = 0.0
                    }
                }
        }
    }

    @ViewBuilder
    func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .bold()
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
        .padding()
    }

    func deposit(amount: String, address: String) async {
        print("Depositing amount: \(amount) to \(address)")

        guard let depositAddress = await requestAddressToDeposit() else {
            self.alertMessage = "Failed to get contract address"
            self.showAlert = true
            return
        }

        if depositAddress.isEmpty {
            return
        }
        
        guard let amountDouble = Double(amount.replacingOccurrences(of: ",", with: "."))  else {
            self.alertMessage = "Please, provide correct amount"
            self.showAlert = true
            return
        }
        
        if amountDouble <= 0 {
            self.alertMessage = "Amount must be greater than 0"
            self.showAlert = true
            return
        }
        
        let encodedCallData = encodeCallData(to: depositAddress, value: amountDouble)
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
            self.alertMessage = "Invalid URL"
            self.showAlert = true
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
            
            URLSession.shared.dataTask(with: request) { _, response, error in
                if let error = error {
                    self.alertMessage = error.localizedDescription
                    self.showAlert = true
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    print("Deposit succesfull")
                } else {
                    self.alertMessage = "Failed to deposit"
                    self.showAlert = true
                }
            }.resume()
        } catch {
            self.alertMessage = error.localizedDescription
            self.showAlert = true
        }
        
    }
    
    func connectMetamask() async {
        await disconnectSDK()
        
        print("Hello before connectAndSign")
        let connect = await metaMaskSDK.connect()
        
        print("connect Result: \(connect)")
        
        switch connect {
        case .success(_):
            print("Sign a message")
            userModel.status = "Connected"
            alertMessage = "Succesfully signed"
            showAlert = true
        case let .failure(error):
            print("Hmm")
            alertMessage = error.localizedDescription
            showAlert = true
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
            } catch {
                self.alertMessage = error.localizedDescription
                showAlert = true
            }
        case let .failure(error):
            alertMessage = error.localizedDescription
            showAlert = true
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
            userModel.status = "Offline"
        }
    
    
    public func sendMessageToServer(message: String, signature: String, address: String) async throws {
        guard let url = URL(string: "http://192.168.1.101:3000/auth") else {
            self.alertMessage = "Invalid URL"
            self.showAlert = true
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
                        
                        userModel.status = "Signed"
                        messageSigned = true
                        
                    } catch {
                        self.alertMessage = "Error decoding response: \(error.localizedDescription)"
                        self.showAlert = true
                        messageSigned = false
                    }
                }
            } else {
                self.alertMessage = "Message not verified"
                self.showAlert = true
            }
        } catch {
                self.alertMessage = "Error: \(error.localizedDescription)"
                self.showAlert = true
        }
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
    
    func withdraw(amount: String, address: String) async {
        guard let url = URL(string: "http://192.168.1.101:3000/private/withdraw") else {
            self.alertMessage = "Invalid URL"
            self.showAlert = true
            return
        }
        
        print("Withdrawwing")
        
        guard let amountDouble = Double(amount) else {
            self.alertMessage = "Invalid amount"
            self.showAlert = true
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
            
            URLSession.shared.dataTask(with: request) { _, response, error in
                if let error = error {
                    self.alertMessage = error.localizedDescription
                    self.showAlert = true
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    print("Withdraw succesfull")
                } else {
                    self.alertMessage = "Failed to withdraw"
                    self.showAlert = true
                }
            }.resume()
        } catch {
            self.alertMessage = error.localizedDescription
            
        }
    }
    
    
    func requestAddressToDeposit() async -> String? {
        print("Requesting address to deposit")
        guard let url = URL(string: "http://192.168.1.101:3000/public/address") else {
            print("Invalid URL")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoder = JSONDecoder()
            let addressResponse = try decoder.decode(depositAddressResponse.self, from: data)
            
            let depositAddress = addressResponse.address
            print("Deposit Address: \(depositAddress)")
            return depositAddress
        } catch {
            print("Error requesting deposit address: \(error)")
            return nil
        }
    }
    
    func getBalance() async -> Double? {
        print("Requesting balance")
        guard let url = URL(string: "http://192.168.1.101:3000/private/balance") else {
            print("Invalid URL")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoder = JSONDecoder()
            let balanceResponce = try decoder.decode(BalanceResponse.self, from: data)
            
            return Double(balanceResponce.balance) / pow(10, 6)
        } catch {
            print("Error requesting user balance: \(error)")
            return nil
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
