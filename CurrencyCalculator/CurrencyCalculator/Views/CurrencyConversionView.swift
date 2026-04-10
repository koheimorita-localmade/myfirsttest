import SwiftUI

struct CurrencyConversionView: View {
    let amount: Double
    @ObservedObject var converter: CurrencyConverter
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header: base amount
                    VStack(spacing: 8) {
                        Text("換算元")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        HStack(spacing: 8) {
                            Text(converter.baseCurrency.flag)
                                .font(.title)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(formatAmount(amount, currency: converter.baseCurrency))
                                    .font(.system(size: 28, weight: .bold))
                                Text(converter.baseCurrency.name)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding()

                    // Base currency picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(CurrencyConverter.supportedCurrencies) { currency in
                                Button(action: {
                                    converter.changeBaseCurrency(to: currency)
                                    Task { await converter.fetchRates() }
                                }) {
                                    HStack(spacing: 4) {
                                        Text(currency.flag)
                                        Text(currency.id)
                                            .font(.caption.bold())
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        currency.id == converter.baseCurrency.id
                                            ? Color.blue
                                            : Color(.systemGray5)
                                    )
                                    .foregroundColor(
                                        currency.id == converter.baseCurrency.id
                                            ? .white
                                            : .primary
                                    )
                                    .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Loading / Error
                    if converter.isLoading {
                        ProgressView("レートを取得中...")
                            .padding()
                    } else if let error = converter.errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }

                    // Conversion results
                    List {
                        ForEach(converter.convertAll(amount: amount), id: \.currency.id) { item in
                            HStack {
                                Text(item.currency.flag)
                                    .font(.title2)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.currency.name)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text(item.currency.id)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Text(formatAmount(item.converted, currency: item.currency))
                                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.insetGrouped)

                    // Last updated
                    if let updated = converter.lastUpdated {
                        Text("最終更新: \(updated, formatter: Self.timeFormatter)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 8)
                    }
                }
            }
            .navigationTitle("通貨換算")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        Task { await converter.fetchRates() }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
    }

    private func formatAmount(_ value: Double, currency: Currency) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = (currency.id == "JPY" || currency.id == "KRW") ? 0 : 2
        formatter.minimumFractionDigits = (currency.id == "JPY" || currency.id == "KRW") ? 0 : 2
        let formatted = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        return "\(currency.symbol)\(formatted)"
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateStyle = .none
        f.timeStyle = .medium
        return f
    }()
}

#Preview {
    CurrencyConversionView(
        amount: 1500,
        converter: CurrencyConverter()
    )
}
