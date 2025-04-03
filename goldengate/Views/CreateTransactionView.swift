import SwiftUI
import Combine

public struct CreateTransactionView: View {
    var selectedOffer: Offer
    @State private var amountToBuy: String = ""
    @State private var calculatedTotal: Double = 0.0
    @State private var totalAmount: Double = 0.0
    @State private var takerFee: Double = 0.5
    
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
                Text("\(selectedOffer.amount) \(selectedOffer.cryptoCurrency)")
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
                createTransaction()
            }) {
                Text("Create Transaction")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .font(.title3)
                    .cornerRadius(8)
                    .padding(.horizontal)
            }
            .padding(.bottom, 20)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Create Transaction")
        .onReceive(
            Publishers.CombineLatest(Just(amountToBuy), Just(selectedOffer.pricePerUnit))
        ) { amountStr, price in
            let decimalSeparator = Locale.current.decimalSeparator ?? "."

            let amount = Double(amountStr
                .replacingOccurrences(of: ",", with: ".")
                .replacingOccurrences(of: decimalSeparator, with: ".")) ?? 0

            calculatedTotal = ((amount * price) / (1 - takerFee/100)).rounded(toPlaces: 2, rule: .up)
            totalAmount = amount
        }
    }
    
    private func createTransaction() {
        print("Transaction Created: \(amountToBuy) \(selectedOffer.cryptoCurrency) for \(calculatedTotal) \(selectedOffer.currency)")
    }
}

#Preview {
    OffersView()
}
