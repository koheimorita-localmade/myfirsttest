import Foundation

enum Operation {
    case add, subtract, multiply, divide
}

struct CalculatorEngine {
    private var accumulator: Double = 0
    private var pendingOperation: Operation?
    private var pendingOperand: Double?
    private var hasResult = false

    var result: Double {
        accumulator
    }

    var resultAvailable: Bool {
        hasResult
    }

    mutating func setOperand(_ operand: Double) {
        if hasResult {
            clear()
        }
        accumulator = operand
    }

    mutating func setOperation(_ operation: Operation) {
        pendingOperand = accumulator
        pendingOperation = operation
        hasResult = false
    }

    mutating func evaluate() {
        guard let operand = pendingOperand, let operation = pendingOperation else {
            hasResult = true
            return
        }

        switch operation {
        case .add:
            accumulator = operand + accumulator
        case .subtract:
            accumulator = operand - accumulator
        case .multiply:
            accumulator = operand * accumulator
        case .divide:
            if accumulator != 0 {
                accumulator = operand / accumulator
            } else {
                accumulator = .nan
            }
        }

        pendingOperand = nil
        pendingOperation = nil
        hasResult = true
    }

    mutating func clear() {
        accumulator = 0
        pendingOperation = nil
        pendingOperand = nil
        hasResult = false
    }

    mutating func toggleSign() {
        accumulator = -accumulator
    }

    mutating func applyPercentage() {
        accumulator = accumulator / 100.0
    }
}
