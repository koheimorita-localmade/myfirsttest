import Foundation
import SwiftUI

@MainActor
class CalculatorViewModel: ObservableObject {
    @Published var displayText = "0"
    @Published var showCurrencySheet = false
    @Published var currentOperationSymbol: String?

    private var engine = CalculatorEngine()
    let currencyConverter = CurrencyConverter()

    private var isTypingNumber = false
    private var hasDecimalPoint = false

    // MARK: - Display

    var resultForConversion: Double {
        engine.result
    }

    var canConvertCurrency: Bool {
        engine.resultAvailable && !engine.result.isNaN && engine.result != 0
    }

    // MARK: - Number Input

    func numberPressed(_ digit: String) {
        if isTypingNumber {
            if displayText == "0" && digit != "." {
                displayText = digit
            } else {
                displayText += digit
            }
        } else {
            displayText = digit
            isTypingNumber = true
        }
    }

    func decimalPressed() {
        if !isTypingNumber {
            displayText = "0."
            isTypingNumber = true
            hasDecimalPoint = true
        } else if !hasDecimalPoint {
            displayText += "."
            hasDecimalPoint = true
        }
    }

    // MARK: - Operations

    func operationPressed(_ op: Operation) {
        if isTypingNumber {
            engine.setOperand(Double(displayText) ?? 0)
        }
        engine.setOperation(op)
        isTypingNumber = false
        hasDecimalPoint = false

        switch op {
        case .add: currentOperationSymbol = "+"
        case .subtract: currentOperationSymbol = "-"
        case .multiply: currentOperationSymbol = "×"
        case .divide: currentOperationSymbol = "÷"
        }
    }

    func equalsPressed() {
        if isTypingNumber {
            engine.setOperand(Double(displayText) ?? 0)
        }
        engine.evaluate()
        displayText = formatResult(engine.result)
        isTypingNumber = false
        hasDecimalPoint = false
        currentOperationSymbol = nil
    }

    func clearPressed() {
        engine.clear()
        displayText = "0"
        isTypingNumber = false
        hasDecimalPoint = false
        currentOperationSymbol = nil
    }

    func toggleSignPressed() {
        if isTypingNumber, let value = Double(displayText) {
            let toggled = -value
            displayText = formatResult(toggled)
            engine.setOperand(toggled)
        } else {
            engine.toggleSign()
            displayText = formatResult(engine.result)
        }
    }

    func percentPressed() {
        if isTypingNumber, let value = Double(displayText) {
            let pct = value / 100.0
            displayText = formatResult(pct)
            engine.setOperand(pct)
        } else {
            engine.applyPercentage()
            displayText = formatResult(engine.result)
        }
    }

    // MARK: - Currency Conversion

    func openCurrencyConversion() {
        showCurrencySheet = true
        Task {
            await currencyConverter.fetchRates()
        }
    }

    // MARK: - Formatting

    private func formatResult(_ value: Double) -> String {
        if value.isNaN {
            return "エラー"
        }
        if value == .infinity || value == -.infinity {
            return "エラー"
        }
        // Remove trailing zeros for clean display
        if value == floor(value) && abs(value) < 1e15 {
            return String(format: "%.0f", value)
        }
        let formatted = String(format: "%.10g", value)
        return formatted
    }
}
