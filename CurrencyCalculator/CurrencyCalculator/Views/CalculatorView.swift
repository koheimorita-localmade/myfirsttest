import SwiftUI

struct CalculatorView: View {
    @StateObject private var viewModel = CalculatorViewModel()

    private let spacing: CGFloat = 12

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 12) {
                Spacer()

                // Operation indicator
                if let opSymbol = viewModel.currentOperationSymbol {
                    HStack {
                        Spacer()
                        Text(opSymbol)
                            .font(.system(size: 24))
                            .foregroundColor(.orange)
                            .padding(.trailing, 24)
                    }
                }

                // Display
                HStack {
                    Spacer()
                    Text(viewModel.displayText)
                        .font(.system(size: displayFontSize, weight: .light))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.4)
                        .padding(.horizontal, 24)
                }

                // Currency conversion button
                if viewModel.canConvertCurrency {
                    Button(action: { viewModel.openCurrencyConversion() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "coloncurrencysign.circle")
                            Text("通貨に換算")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.blue.opacity(0.7))
                        .clipShape(Capsule())
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .animation(.easeInOut(duration: 0.25), value: viewModel.canConvertCurrency)
                }

                // Button grid
                VStack(spacing: spacing) {
                    // Row 1: AC, +/-, %, ÷
                    HStack(spacing: spacing) {
                        calcButton(.clear) { viewModel.clearPressed() }
                        calcButton(.toggleSign) { viewModel.toggleSignPressed() }
                        calcButton(.percent) { viewModel.percentPressed() }
                        calcButton(.operation(.divide, "÷")) { viewModel.operationPressed(.divide) }
                    }

                    // Row 2: 7, 8, 9, ×
                    HStack(spacing: spacing) {
                        calcButton(.number("7")) { viewModel.numberPressed("7") }
                        calcButton(.number("8")) { viewModel.numberPressed("8") }
                        calcButton(.number("9")) { viewModel.numberPressed("9") }
                        calcButton(.operation(.multiply, "×")) { viewModel.operationPressed(.multiply) }
                    }

                    // Row 3: 4, 5, 6, -
                    HStack(spacing: spacing) {
                        calcButton(.number("4")) { viewModel.numberPressed("4") }
                        calcButton(.number("5")) { viewModel.numberPressed("5") }
                        calcButton(.number("6")) { viewModel.numberPressed("6") }
                        calcButton(.operation(.subtract, "-")) { viewModel.operationPressed(.subtract) }
                    }

                    // Row 4: 1, 2, 3, +
                    HStack(spacing: spacing) {
                        calcButton(.number("1")) { viewModel.numberPressed("1") }
                        calcButton(.number("2")) { viewModel.numberPressed("2") }
                        calcButton(.number("3")) { viewModel.numberPressed("3") }
                        calcButton(.operation(.add, "+")) { viewModel.operationPressed(.add) }
                    }

                    // Row 5: 0, ., =
                    HStack(spacing: spacing) {
                        calcButton(.number("0")) { viewModel.numberPressed("0") }
                        calcButton(.decimal) { viewModel.decimalPressed() }
                        calcButton(.equals) { viewModel.equalsPressed() }
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $viewModel.showCurrencySheet) {
            CurrencyConversionView(
                amount: viewModel.resultForConversion,
                converter: viewModel.currencyConverter
            )
        }
    }

    private var displayFontSize: CGFloat {
        let length = viewModel.displayText.count
        if length > 12 { return 40 }
        if length > 9 { return 55 }
        return 72
    }

    @ViewBuilder
    private func calcButton(_ type: CalculatorButtonType, action: @escaping () -> Void) -> some View {
        CalculatorButtonView(type: type, action: action)
    }
}

#Preview {
    CalculatorView()
}
