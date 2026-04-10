import Foundation

struct Currency: Identifiable, Hashable {
    let id: String // ISO 4217 code
    let name: String
    let symbol: String
    let flag: String
}

struct ExchangeRateResponse: Codable {
    let result: String
    let rates: [String: Double]

    enum CodingKeys: String, CodingKey {
        case result
        case rates = "conversion_rates"
    }
}

@MainActor
class CurrencyConverter: ObservableObject {
    @Published var rates: [String: Double] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var baseCurrency: Currency
    @Published var lastUpdated: Date?

    static let supportedCurrencies: [Currency] = [
        Currency(id: "JPY", name: "日本円", symbol: "¥", flag: "🇯🇵"),
        Currency(id: "USD", name: "米ドル", symbol: "$", flag: "🇺🇸"),
        Currency(id: "EUR", name: "ユーロ", symbol: "€", flag: "🇪🇺"),
        Currency(id: "GBP", name: "英ポンド", symbol: "£", flag: "🇬🇧"),
        Currency(id: "CNY", name: "中国元", symbol: "¥", flag: "🇨🇳"),
        Currency(id: "KRW", name: "韓国ウォン", symbol: "₩", flag: "🇰🇷"),
        Currency(id: "AUD", name: "豪ドル", symbol: "A$", flag: "🇦🇺"),
        Currency(id: "CAD", name: "カナダドル", symbol: "C$", flag: "🇨🇦"),
        Currency(id: "CHF", name: "スイスフラン", symbol: "CHF", flag: "🇨🇭"),
        Currency(id: "THB", name: "タイバーツ", symbol: "฿", flag: "🇹🇭"),
    ]

    init(baseCurrency: Currency? = nil) {
        self.baseCurrency = baseCurrency ?? Self.supportedCurrencies[0]
        loadDefaultRates()
    }

    /// Fetches live exchange rates from the API
    func fetchRates() async {
        isLoading = true
        errorMessage = nil

        let urlString = "https://open.er-api.com/v6/latest/\(baseCurrency.id)"
        guard let url = URL(string: urlString) else {
            errorMessage = "無効なURLです"
            isLoading = false
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(OpenERResponse.self, from: data)
            rates = response.rates
            lastUpdated = Date()
            errorMessage = nil
        } catch {
            errorMessage = "レート取得に失敗しました。デフォルトレートを使用します。"
            loadDefaultRates()
        }

        isLoading = false
    }

    /// Converts the given amount from the base currency to the target currency
    func convert(amount: Double, to target: Currency) -> Double? {
        guard let rate = rates[target.id] else { return nil }
        return amount * rate
    }

    /// Returns all conversion results for the given amount
    func convertAll(amount: Double) -> [(currency: Currency, converted: Double)] {
        Self.supportedCurrencies.compactMap { currency in
            guard currency.id != baseCurrency.id,
                  let converted = convert(amount: amount, to: currency) else {
                return nil
            }
            return (currency: currency, converted: converted)
        }
    }

    func changeBaseCurrency(to currency: Currency) {
        baseCurrency = currency
        loadDefaultRates()
    }

    // MARK: - Private

    private func loadDefaultRates() {
        // Approximate rates as of 2025 (fallback when API is unavailable)
        let defaultRatesFromJPY: [String: Double] = [
            "JPY": 1.0,
            "USD": 0.0067,
            "EUR": 0.0061,
            "GBP": 0.0053,
            "CNY": 0.0483,
            "KRW": 8.93,
            "AUD": 0.0103,
            "CAD": 0.0092,
            "CHF": 0.0059,
            "THB": 0.233,
        ]

        if baseCurrency.id == "JPY" {
            rates = defaultRatesFromJPY
        } else {
            // Convert through JPY
            guard let baseFromJPY = defaultRatesFromJPY[baseCurrency.id], baseFromJPY != 0 else {
                rates = [:]
                return
            }
            var converted: [String: Double] = [:]
            for (code, rateFromJPY) in defaultRatesFromJPY {
                converted[code] = rateFromJPY / baseFromJPY
            }
            rates = converted
        }
    }
}

// Response model for open.er-api.com
private struct OpenERResponse: Codable {
    let result: String
    let rates: [String: Double]

    enum CodingKeys: String, CodingKey {
        case result
        case rates
    }
}
