import SwiftUI

@main
struct CurrencyCalculatorApp: App {
    var body: some Scene {
        WindowGroup {
            CalculatorView()
                .preferredColorScheme(.dark)
        }
    }
}
