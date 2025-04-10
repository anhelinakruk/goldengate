import SwiftUI
import Combine

public struct CreateOfferView: View {
    @State private var cryptoAmount: String = ""
    @State private var pricePerUnit: String = ""
    @State private var selectedCurrency: String = "PLN"
    @State private var selectedCryptoType: String = "USDT"
    @State private var makerFeeRate: Double = 0.5
    @State private var makerFee: Double = 0.0
    @State private var calculatedValue: Double = 0.0
    @State private var selectedOfferType: String = "Buy"
    @State private var revTag: String = ""
    
    @State private var calculatedPrice: Double = 0.0

    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    @FocusState private var focusedField: Field?
    enum Field {
            case cryptoAmount
            case pricePerUnit
            case revTag
        }
    
    let cryptoOptions = ["USDT",]
    let currencyOptions = ["PLN", "USD", "EUR"]
    let offerTypes = ["Buy", "Sell"]
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                HStack {
                    Text("Offer Type:")
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    Spacer()
                    Picker("Offer Type", selection: $selectedOfferType) {
                        ForEach(offerTypes, id: \.self) { offerType in
                            Text(offerType)
                                .foregroundColor(.blue)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 120)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    .shadow(radius: 3)
                }
                .padding(.bottom, 15)
                
                HStack {
                    Text("Crypto Currency:")
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    Spacer()
                    Picker("Crypto", selection: $selectedCryptoType) {
                        ForEach(cryptoOptions, id: \.self) { crypto in
                            Text(crypto)
                                .foregroundColor(.blue)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 120)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    .shadow(radius: 3)
                }
                .padding(.bottom, 15)
                
                HStack {
                    Text("Amount:")
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    Spacer()
                    TextField("Enter amount", text: $cryptoAmount)
                        .numbersOnly($cryptoAmount, maxDecimalPlaces: 6)
                        .padding(10)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .shadow(radius: 3)
                        .focused($focusedField, equals: .cryptoAmount)
                }
                .padding(.bottom, 15)
                
                HStack {
                    Text("Currency:")
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    Spacer()
                    Picker("Currency", selection: $selectedCurrency) {
                        ForEach(currencyOptions, id: \.self) { currency in
                            Text(currency)
                                .foregroundColor(.blue)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 120)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    .shadow(radius: 3)
                }
                .padding(.bottom, 15)
                
                HStack {
                    Text("Price per unit:")
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    Spacer()
                    TextField("Enter price", text: $pricePerUnit)
                        .numbersOnly($pricePerUnit, maxDecimalPlaces: 4)
                        .padding(10)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .shadow(radius: 3)
                        .focused($focusedField, equals: .pricePerUnit)
                }
                .padding(.bottom, 15)
                
                HStack {
                    Text("You revTag:")
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    Spacer()
                    TextField("Enter revTag", text: $revTag)
                        .padding(10)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .shadow(radius: 3)
                        .focused($focusedField, equals: .revTag)
                }
                .padding(.bottom, 15)
                
                HStack {
                    Text("Fee (0.5%):")
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    Spacer()
                    Text("\(makerFee)")
                        .foregroundColor(.black)
                }
                .padding(.bottom, 15)
                
                HStack {
                    Text("You will pay:")
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    Spacer()
                    Text("\(calculatedValue, specifier: "%.6f") \(selectedCryptoType)")
                        .foregroundColor(.black)
                }
                .padding(.bottom, 15)
                
                HStack {
                    Text("Offer Value:")
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    Spacer()
                    Text("\(calculatedPrice, specifier: "%.2f") \(selectedCurrency)")
                        .foregroundColor(.black)
                }
                .padding(.bottom, 15)
                
                Button(action: {
                    if cryptoAmount.isEmpty || pricePerUnit.isEmpty {
                        alertMessage = "Please fill in both Amount and Price per unit."
                        showAlert = true
                    } else {
                        guard let amount = Double(cryptoAmount.replacingOccurrences(of: ",", with: ".")) else {
                                    alertMessage = "Please enter a valid amount."
                                    showAlert = true
                                    return
                                }
                                
                        guard let price = Double(pricePerUnit.replacingOccurrences(of: ",", with: ".")) else {
                            alertMessage = "Please enter a valid price per unit."
                            showAlert = true
                            return
                        }
                        
                        let amountToSend = Int(amount * pow(10, 6))
                        let priceToSend = Int(price * pow(10, 2))
                        let value = Int(calculatedValue * pow(10, 6))
                        let fee = Int(makerFee * pow(10, 6))
                        
                        let offer = OfferRequest(
                            offerType: selectedOfferType,
                            amount: amountToSend,
                            fee: fee,
                            cryptoType: selectedCryptoType,
                            currency: selectedCurrency,
                            pricePerUnit: priceToSend,
                            value: value,
                            revTag: revTag
                        )

                        createOfferRequest(offer: offer) { result in
                            switch result {
                            case .success(_):
                                print("Offer Created Successfully!")
                            case .failure(let error):
                                print("Failed to create offer: \(error.localizedDescription)")
                            }
                        }
                    }
                }) {
                    Text("Create Offer")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .font(.title3)
                        .cornerRadius(8)
                        .shadow(radius: 5)
                        .padding(.horizontal)
                }
                Spacer()
            }
            .padding()
            .navigationTitle("Create Offer")
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Missing Information"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .onReceive(
                Publishers.CombineLatest(Just(cryptoAmount), Just(pricePerUnit))
            ) { amountStr, priceStr in
                let decimalSeparator = Locale.current.decimalSeparator ?? "."

                let amount = Double(amountStr
                    .replacingOccurrences(of: ",", with: ".")
                    .replacingOccurrences(of: decimalSeparator, with: ".")) ?? 0

                let price = Double(priceStr
                    .replacingOccurrences(of: ",", with: ".")
                    .replacingOccurrences(of: decimalSeparator, with: ".")) ?? 0

                calculatedPrice = amount * price
                calculatedValue = (amount * (1 + makerFeeRate / 100)).rounded(toPlaces: 6, rule: .up)
                let fee = (amount * (makerFeeRate / 100)).rounded(toPlaces: 6, rule: .up)
                makerFee = fee
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
        .onTapGesture {
            focusedField = nil
        }
    }
    
    func createOfferRequest(offer: OfferRequest, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let url = URL(string: "http://192.168.1.101:3000/private/offers") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 400, userInfo: nil)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(offer)
            request.httpBody = data
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    completion(.success(true))
                } else {
                    completion(.failure(NSError(domain: "Request failed", code: 500, userInfo: nil)))
                }
            }.resume()
        } catch {
            completion(.failure(error))
        }
    }
}

extension Double {
    func rounded(toPlaces places: Int, rule: FloatingPointRoundingRule) -> Double {
        let multiplier = pow(10.0, Double(places))
        return (self * multiplier).rounded(rule) / multiplier
    }
}

#Preview {
    CreateOfferView()
}

