import SwiftUI
import Combine


struct NumbersOnlyViewModifier: ViewModifier {
    @Binding var text: String
    var maxDecimalPlaces: Int?
    
    func body(content: Content) -> some View {
        content
            .keyboardType(.decimalPad)
            .onReceive(Just(text)) { newValue in
                let decimalSeparator = Locale.current.decimalSeparator ?? "."
                let allowedCharacters = "0123456789" + decimalSeparator

                var filtered = newValue.filter { allowedCharacters.contains($0) }

                let decimalParts = filtered.components(separatedBy: decimalSeparator)
                if decimalParts.count > 2 {
                    filtered = String(filtered.dropLast())
                }

                if let maxDecimalPlaces,
                   decimalParts.count == 2,
                   decimalParts[1].count > maxDecimalPlaces {
                    
                    let integerPart = decimalParts[0]
                    let fractionalPart = String(decimalParts[1].prefix(maxDecimalPlaces))
                    filtered = integerPart + decimalSeparator + fractionalPart
                }

                if filtered != newValue {
                    self.text = filtered
                }
            }
    }
}

extension View {
    func numbersOnly(_ text:Binding<String>, maxDecimalPlaces: Int? = nil) -> some View {
        self.modifier(NumbersOnlyViewModifier(text: text, maxDecimalPlaces: maxDecimalPlaces))
    }
}
