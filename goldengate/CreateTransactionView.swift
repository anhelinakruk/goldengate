import SwiftUI

public struct CreateTransactionView: View {
    var selectedOffer: Offer
    @State private var amountToBuy: String = "" // Amount user wants to buy
    @State private var calculatedTotal: Double = 0.0
    
    public var body: some View {
        VStack {
            HStack {
                Text("Price per unit:")
                    .fontWeight(.bold)
                Spacer()
                Text("\(selectedOffer.price) \(selectedOffer.currency)")
                    .foregroundColor(.black)
            }
            .padding(.bottom, 10)
            
            // Available amount
            HStack {
                Text("Available:")
                    .fontWeight(.bold)
                Spacer()
                Text("\(selectedOffer.amount) \(selectedOffer.cryptoCurrency)")
                    .foregroundColor(.black)
            }
            .padding(.bottom, 10)
            
            // Amount user wants to buy
            HStack {
                Text("Amount to buy:")
                    .fontWeight(.bold)
                Spacer()
                TextField("Enter amount", text: $amountToBuy)
                    .keyboardType(.decimalPad)
                    .padding(10)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .onChange(of: amountToBuy) { newValue in
                        calculateTotal()
                    }
            }
            .padding(.bottom, 10)
            
            // Total price after selecting amount
            HStack {
                Text("Total Price:")
                    .fontWeight(.bold)
                Spacer()
                Text("\(calculatedTotal, specifier: "%.2f") \(selectedOffer.currency)")
                    .foregroundColor(.black)
            }
            .padding(.bottom, 10)
            
            // Create Transaction Button
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
    }
    
    private func calculateTotal() {
        guard let amountValue = Double(amountToBuy) else {
            calculatedTotal = 0.0
            return
        }
        
        calculatedTotal = amountValue * Double(selectedOffer.price)
    }
    
    private func createTransaction() {
        print("Transaction Created: \(amountToBuy) \(selectedOffer.cryptoCurrency) for \(calculatedTotal) \(selectedOffer.currency)")
    }
}

#Preview {
    OffersView()
}
