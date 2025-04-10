import Foundation

struct ResponseMessage: Decodable {
    let access_token: String
}

struct NonceResponse: Decodable {
    let message: String
}

struct OfferRequest: Codable {
    var offerType: String
    var amount: Int
    var fee: Int
    var cryptoType: String
    var currency: String
    var pricePerUnit: Int
    var value: Int
    var revTag: String
}

struct ResponseOffer: Codable {
    let id: String
    var offerType: String
    var pricePerUnit: Int
    var currency: String
    var amount: Int
    var cryptoType: String
    var fee: Int
    var status: String
    var value: Int
    var revTag: String
}

struct TransactionRequest: Codable {
    let offerId: String
    var amount: Int
    var cryptoType: String
    var pricePerUnit: Int
    var currency: String
    var takerFee: Int
    var makerFee: Int
    var value: Int
    var randomTitle: String
}


struct AggregatedFeeRequest: Codable {
    let offerId: String
}


struct AggregatedFeeResponse: Decodable {
    var aggregatedFee: Int
}

struct confirmDepositRequest: Codable {
    var txHash: String
    var amount: Int
}

struct confirmDepositResponse: Decodable {
    let id: String
    var balance: Int
}


struct withdrawRequest: Codable {
    var amount: Int
    var address: String
}
