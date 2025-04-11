import SwiftUI

public struct UserOfferView: View {
    @State private var offers: [Offer] = []
    @State private var selectedOfferType: String = "Buy"
    @State private var selectedCrypto: String = "USDT"
    
    let cryptoOptions = ["USDT"]
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    @EnvironmentObject var userModel: UserModel
    
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
                    let filteredOffers = offers.filter {
                        $0.offerType == selectedOfferType &&
                        $0.cryptoCurrency == selectedCrypto
                    }
                    
                    if filteredOffers.isEmpty {
                        GeometryReader { geometry in
                            Text("No Offers Found")
                                .font(.headline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
                        }
                        .frame(minHeight: 300)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(filteredOffers) { offer in
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
                                        Text("\(offer.amount) \(offer.cryptoCurrency)")
                                            .foregroundColor(.black)
                                        Spacer()
                                        Button(action: {
                                            Task {
                                                await closeOfferRequest(offer: offer) { result in
                                                    switch result {
                                                    case .success(_):
                                                        print("Offer Closed Successfully!")
                                                    case .failure(let error):
                                                        print("Failed to close offer: \(error.localizedDescription)")
                                                    }
                                                }
                                            }
                                        }) {
                                            Text("Delete offer")
                                                .padding(10)
                                                .font(.footnote)
                                                .background(Color.red)
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
                }
                
                Spacer()
                

                if userModel.status == "Signed" {
                    NavigationLink(destination: CreateOfferView().environmentObject(userModel)) {
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
                } else {
                    Button {
                        alertMessage = "You need to sign your message to create an offer."
                        showAlert = true
                    } label: {
                        Text("Create Offer")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.5))
                            .foregroundColor(.white)
                            .font(.title3)
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }
                    .padding(.bottom)
                }
            }
            .navigationBarTitle("Your offers")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.gray.opacity(0.1))
            .onAppear {
                fetchUserOffers()
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Warning"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    func closeOfferRequest(offer: Offer, completion: @escaping (Result<Bool, Error>) -> Void) async {
        print("Closing offer: \(offer.id)")
        guard let url = URL(string: "http://192.168.1.101:3000/private/user/offers/\(offer.id)") else {
            print("Invalid URL")
            completion(.failure(NSError(domain: "InvalidURL", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
            
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error deleting offer: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 204 {
                    print("Offer \(offer.id) deleted successfully.")
                    DispatchQueue.main.async {
                        self.offers.removeAll { $0.id == offer.id }
                        completion(.success(true))
                    }
                } else {
                    let error = NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to delete offer. Status code: \(httpResponse.statusCode)"])
                    print("Failed to delete offer. Status code: \(httpResponse.statusCode)")
                    completion(.failure(error))
                }
            } else {
                let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
                completion(.failure(error))
            }
        }.resume()
    }
        
    func fetchUserOffers() {
        guard let url = URL(string: "http://192.168.1.101:3000/private/user/offers") else {
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
                
                print("Offers \(offersResponse)")
                
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

#Preview {
    UserOfferView()
}
