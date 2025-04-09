import SwiftUI
import Combine

public struct CreateTransactionView: View {
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""
    
    var selectedOffer: Offer
    @State private var amountToBuy: String = ""
    @State private var calculatedTotal: Double = 0.0
    @State private var totalAmount: Double = 0.0
    @State private var takerFeeRate: Double = 0.5
    @State private var takerFee: Double = 0.0
    
    public var body: some View {
        VStack {
            HStack {
                Text("Price per unit:")
                    .fontWeight(.bold)
                Spacer()
                Text("\(selectedOffer.pricePerUnit, specifier: "%.2f") \(selectedOffer.currency)")
                    .foregroundColor(.black)
            }
            .padding(.bottom, 10)
            
            HStack {
                Text("Available:")
                    .fontWeight(.bold)
                Spacer()
                Text("\((selectedOffer.amount - (selectedOffer.amount * (takerFeeRate/100))).rounded(toPlaces: 6, rule: .down)) \(selectedOffer.cryptoCurrency)")
                    .foregroundColor(.black)
            }
            .padding(.bottom, 10)
            
            HStack {
                Text("Amount to buy:")
                    .fontWeight(.bold)
                Spacer()
                TextField("Enter amount", text: $amountToBuy)
                    .numbersOnly($amountToBuy, maxDecimalPlaces: 6)
                    .padding(10)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            .padding(.bottom, 10)
            
            HStack {
                Text("You will pay:")
                    .fontWeight(.bold)
                Spacer()
                Text("\(calculatedTotal, specifier: "%.2f") \(selectedOffer.currency)")
                    .foregroundColor(.black)
            }
            .padding(.bottom, 10)
            
            HStack {
                Text("You will get:")
                    .fontWeight(.bold)
                Spacer()
                Text("\(totalAmount, specifier: "%.6f") \(selectedOffer.cryptoCurrency)")
                    .foregroundColor(.black)
            }
            .padding(.bottom, 10)

            
            Button(action: {
                if amountToBuy.isEmpty {
                    alertMessage = "Please fill in amount field."
                    showAlert = true
                } else {
                    guard let amount = Double(amountToBuy.replacingOccurrences(of: ",", with: ".")), amount > 0 else {
                                alertMessage = "Please enter a valid amount."
                                showAlert = true
                                return
                            }
                    
                    let value = amount * selectedOffer.pricePerUnit
                    let valueAfterFee = (value / (1 - (takerFeeRate/100))).rounded(toPlaces: 2, rule: .down)
                    
                    let amountAfterFee = amount / (1 - takerFeeRate / 100)
                    let takerFee = amountAfterFee - amount
                    
                    let amountToSend = Int(amount * pow(10, 6))
                    let priceToSend = Int(selectedOffer.pricePerUnit * pow(10, 2))
                    let valueToSend = Int(valueAfterFee * pow(10, 2))
                    let fee = Int(takerFee * pow(10, 6))
                    
                    let getAggregatedFee = AggregatedFeeRequest (
                        offerId: selectedOffer.id
                    )
                    
                    getAggregatedFeeRequest(request: getAggregatedFee) {result in
                            switch result {
                            case .success(let aggregatedFee):
                                print("Fee agreggated")
                                let makerFee = calculateMakerFeeParcial(
                                    partialAmount: amount+takerFee,
                                    offerFee: selectedOffer.fee-(Double(aggregatedFee.aggregatedFee) / pow(10, 6)),
                                    fullAmount: selectedOffer.amount
                                )
                                
                                let makerFeeInt = Int(makerFee * pow(10, 6))
                            
                                let transaction = TransactionRequest (
                                    offerId: selectedOffer.id,
                                    amount: amountToSend,
                                    cryptoType: selectedOffer.cryptoCurrency,
                                    pricePerUnit: priceToSend,
                                    currency: selectedOffer.currency,
                                    takerFee: fee,
                                    makerFee: makerFeeInt,
                                    value: valueToSend,
                                    randomTitle: "test"
                                )

                                createTransactionRequest(transaction: transaction) { result in
                                    switch result {
                                    case .success(_):
                                        alertTitle = "Transaction Successful"
                                        alertMessage = """
                                        Pay: \(Double(transaction.value) / pow(10, 2)) \(selectedOffer.currency)
                                        RevTag: \(selectedOffer.revTag)
                                        RandomTitle: \(transaction.randomTitle)
                                        """
                                        showAlert = true
                                    case .failure(let error):
                                        alertTitle = "Transaction Failed"
                                        alertMessage = "Failed to create transaction: \(error.localizedDescription)"
                                        showAlert = true
                                    }
                                }
                            case .failure(let error):
                                alertTitle = "Transaction Failed"
                                alertMessage = "Failed to aggregate fee: \(error.localizedDescription)"
                                showAlert = true
                            }
                    };
                }
            }) {
                Text("Create Transaction")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .font(.title3)
                    .cornerRadius(8)
                    .shadow(radius: 5)
                    .padding(.horizontal)
            }
            .padding(.bottom, 20)
            Spacer()
        }
        .padding()
        .alert(isPresented: $showAlert) {
            Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .navigationTitle("Create Transaction")
        .onReceive(
            Publishers.CombineLatest(Just(amountToBuy), Just(selectedOffer.pricePerUnit))
        ) { amountStr, price in
            let decimalSeparator = Locale.current.decimalSeparator ?? "."

            let amount = Double(amountStr
                .replacingOccurrences(of: ",", with: ".")
                .replacingOccurrences(of: decimalSeparator, with: ".")) ?? 0

            calculatedTotal = ((amount * price) / (1 - takerFeeRate/100)).rounded(toPlaces: 2, rule: .down)
            totalAmount = amount
        }
    }
    
    func createTransactionRequest(transaction: TransactionRequest, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let url = URL(string: "http://localhost:3000/private/transactions") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 400, userInfo: nil)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(transaction)
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
    
    func getAggregatedFeeRequest(request: AggregatedFeeRequest, completion: @escaping (Result<AggregatedFeeResponse, Error>) -> Void) {
        guard let url = URL(string: "http://localhost:3000/private/fee") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 400, userInfo: nil)))
            return
        }
        
        print("Aggregating fee")

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(request)
            
            urlRequest.httpBody = data
            
            URLSession.shared.dataTask(with: urlRequest) { data, response, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    guard let data = data else {
                        completion(.failure(NSError(domain: "No data received", code: 404, userInfo: nil)))
                        return
                    }
                    
                    do {
                        let decoder = JSONDecoder()
                        let decodedResponse = try decoder.decode(AggregatedFeeResponse.self, from: data)
                        print("Decoding fee response")
                        completion(.success(decodedResponse))
                    } catch {
                        completion(.failure(error))
                    }
                } else {
                    completion(.failure(NSError(domain: "Request failed", code: 500, userInfo: nil)))
                }
            }.resume()
        } catch {
            completion(.failure(error))
        }
    }
    
    func calculateMakerFeeParcial(partialAmount: Double, offerFee: Double, fullAmount: Double) -> Double {
        let percentage = partialAmount / fullAmount;
        let makerFee = (percentage * offerFee).rounded(toPlaces: 6, rule: .up)
        return makerFee;
    }
}

#Preview {
    OffersView()
}

