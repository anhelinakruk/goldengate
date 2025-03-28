import SwiftUI

public struct CreateOfferView: View {
    @State private var cryptoAmount: String = ""
    @State private var pricePerUnit: String = ""
    @State private var selectedCurrency: String = "USD"
    @State private var selectedCryptoCurrency: String = "BTC"
    @State private var takerFee: Double = 0.5
    @State private var calculatedValue: Double = 0.0
    @State private var selectedOfferType: String = "Buy"
    
    @State private var calculatedPrice: Double = 0.0

    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    let cryptoOptions = ["BTC", "ETH", "LTC", "XRP"]
    let currencyOptions = ["PLN", "USD", "EUR"]
    let offerTypes = ["Buy", "Sell"]
    
    public var body: some View {
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
                Picker("Crypto", selection: $selectedCryptoCurrency) {
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
                    .keyboardType(.decimalPad)
                    .padding(10)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .shadow(radius: 3)
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
                    .keyboardType(.decimalPad)
                    .padding(10)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .shadow(radius: 3)
            }
            .padding(.bottom, 15)
            
            HStack {
                Text("Fee:")
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                Spacer()
                Text("\(takerFee, specifier: "%.2f")% of the amount")
                    .foregroundColor(.black)
            }
            .padding(.bottom, 15)
            
            HStack {
                Text("Full Value:")
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                Spacer()
                Text("\(calculatedValue, specifier: "%.2f") \(selectedCryptoCurrency)")
                    .foregroundColor(.black)
            }
            .padding(.bottom, 15)
            
            HStack {
                Text("Full Price:")
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
                    print("Offer Created!")
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
    }
}

#Preview {
    CreateOfferView()
}
