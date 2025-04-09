import SwiftUI

public struct OffersView: View {
    @State private var offers: [Offer] = []
    @State private var selectedOffer: Offer? = nil
    @State private var selectedOfferType: String = "Buy"
    @State private var selectedCrypto: String = "USDT"
    
    @State private var takerFeeRate = 0.5
    @State private var amountAvailable = 0.0
    
    let cryptoOptions = ["USDT"]
    
    public var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Picker("Offer Type", selection: $selectedOfferType) {
                        Text("Buy").tag("Buy")
                        Text("Sell").tag("Sell")
                    }
                    .font(.title3)
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 200)
                    
                    Spacer()
                    
                    Picker("Crypto", selection: $selectedCrypto) {
                        ForEach(cryptoOptions, id: \.self) { crypto in
                            Text(crypto)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 120)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(offers.filter { $0.offerType == selectedOfferType && $0.cryptoCurrency == selectedCrypto }) { offer in
                            VStack(spacing: 10) {
                                HStack {
                                    Text("Price per unit:")
                                        .fontWeight(.bold)
                                    Text("\(offer.pricePerUnit, specifier: "%.2f") \(offer.currency)")
                                        .foregroundColor(.black)
                                    Spacer()
                                }
                                
                                HStack {
                                    Text("Available:")
                                        .fontWeight(.bold)
                                    Text("\(amountAvailable) \(offer.cryptoCurrency)")
                                        .foregroundColor(.black)
                                    Spacer()
                                    NavigationLink(destination: CreateTransactionView(selectedOffer: offer)) {
                                        Text("Take Offer")
                                            .padding(.all, 10)
                                            .font(.footnote)
                                            .background(Color.blue)
                                            .foregroundColor(.white)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(radius: 5)
                        }
                    }
                    .padding()
                }
                
                Spacer()
                
                NavigationLink(destination: CreateOfferView()) {
                    Text("Create Offer")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .font(.title3)
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
                .padding(.bottom)
            }
            .navigationBarTitle("Offers")
            .background(Color.gray.opacity(0.1))
            .onAppear {
                fetchOffers()
            }
        }
    }
    
    func fetchOffers() {
        guard let url = URL(string: "http://localhost:3000/public/offers") else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching offers: \(error.localizedDescription)")
                return
            }
            guard let data = data else {
                print("No data received")
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let offersResponse = try decoder.decode([ResponseOffer].self, from: data)
                
                let processedOffers = offersResponse.map { responseOffer in
                    let offer = Offer(
                        id: responseOffer.id,
                        offerType: responseOffer.offerType,
                        pricePerUnit: Double(responseOffer.pricePerUnit) / pow(10, 2),
                        currency: responseOffer.currency,
                        amount: Double(responseOffer.amount) / pow(10, 6),
                        cryptoCurrency: responseOffer.cryptoType,
                        fee: Double(responseOffer.fee) / pow(10, 6),
                        status: responseOffer.status,
                        value: Double(responseOffer.value) / pow(10, 6),
                        revTag: responseOffer.revTag
                    )
                    
                    amountAvailable = (offer.amount - (offer.amount * (takerFeeRate/100))).rounded(toPlaces: 6, rule: .down)
                    return offer
                }

                DispatchQueue.main.async {
                    self.offers = processedOffers
                }
            } catch {
                print("Error decoding response: \(error.localizedDescription)")
            }
        }.resume()
    }
}

struct Offer: Identifiable {
    let id: String
    var offerType: String
    var pricePerUnit: Double
    var currency: String
    var amount: Double
    var cryptoCurrency: String
    var fee: Double
    var status: String
    var value: Double
    var revTag: String
}

#Preview {
    OffersView()
}

