//
//  OffersView.swift
//  goldengate
//
//  Created by Anhelina Kruk on 27/03/2025.
//

import SwiftUI

public struct OffersView: View {
    let offers: [Offer] = [
        Offer(id: "1", offerType: "Buy", price: 1000, currency: "USD", amount: 1, cryptoCurrency: "BTC", fee: 50, status: "Active", value: 950, revTag: "Rev1"),
        Offer(id: "1", offerType: "Buy", price: 1000, currency: "USD", amount: 1, cryptoCurrency: "BTC", fee: 50, status: "Active", value: 950, revTag: "Rev1"),
        Offer(id: "1", offerType: "Buy", price: 1000, currency: "USD", amount: 1, cryptoCurrency: "BTC", fee: 50, status: "Active", value: 950, revTag: "Rev1"),
        Offer(id: "1", offerType: "Buy", price: 1000, currency: "USD", amount: 1, cryptoCurrency: "BTC", fee: 50, status: "Active", value: 950, revTag: "Rev1"),
        Offer(id: "1", offerType: "Buy", price: 1000, currency: "USD", amount: 1, cryptoCurrency: "BTC", fee: 50, status: "Active", value: 950, revTag: "Rev1"),
        Offer(id: "2", offerType: "Sell", price: 1200, currency: "USD", amount: 2, cryptoCurrency: "ETH", fee: 60, status: "Active", value: 1140, revTag: "Rev2"),
        Offer(id: "3", offerType: "Buy", price: 800, currency: "USD", amount: 5, cryptoCurrency: "LTC", fee: 40, status: "Inactive", value: 760, revTag: "Rev3")
    ]
    
    @State private var selectedOffer: Offer? = nil
    
    @State private var selectedOfferType: String = "Buy"
    @State private var selectedCrypto: String = "BTC"
    
    let cryptoOptions = ["BTC", "ETH", "LTC", "XRP"]
    
    public var body: some View {
        NavigationView {
            VStack {
                // Picker for selecting offer type and crypto currency
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
                                    Text("\(offer.price) \(offer.currency)")
                                        .foregroundColor(.black)
                                    Spacer()
                                }
                                
                                HStack {
                                    Text("Available:")
                                        .fontWeight(.bold)
                                    Text("\(offer.amount) \(offer.cryptoCurrency)")
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
        }
    }
}

struct Offer: Identifiable {
    let id: String
    var offerType: String
    var price: Int128
    var currency: String
    var amount: Int128
    var cryptoCurrency: String
    var fee: Int128
    var status: String
    var value: Int128
    var revTag: String
}


#Preview {
    OffersView()
}
