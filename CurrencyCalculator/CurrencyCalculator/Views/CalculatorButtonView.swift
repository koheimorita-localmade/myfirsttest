import SwiftUI

enum CalculatorButtonType {
    case number(String)
    case operation(Operation, String)
    case equals
    case clear
    case toggleSign
    case percent
    case decimal
    case currency

    var label: String {
        switch self {
        case .number(let n): return n
        case .operation(_, let s): return s
        case .equals: return "="
        case .clear: return "AC"
        case .toggleSign: return "+/-"
        case .percent: return "%"
        case .decimal: return "."
        case .currency: return "¤"
        }
    }

    var backgroundColor: Color {
        switch self {
        case .number, .decimal:
            return Color(.darkGray)
        case .operation, .equals:
            return .orange
        case .clear, .toggleSign, .percent:
            return Color(.lightGray)
        case .currency:
            return .blue
        }
    }

    var foregroundColor: Color {
        switch self {
        case .clear, .toggleSign, .percent:
            return .black
        default:
            return .white
        }
    }

    var isWide: Bool {
        if case .number("0") = self { return true }
        return false
    }
}

struct CalculatorButtonView: View {
    let type: CalculatorButtonType
    let action: () -> Void

    private let buttonSize: CGFloat = 72
    private let spacing: CGFloat = 12

    var body: some View {
        Button(action: action) {
            Group {
                if case .currency = type {
                    Image(systemName: "yensign.circle.fill")
                        .font(.system(size: 28))
                } else {
                    Text(type.label)
                        .font(.system(size: type.label.count > 2 ? 22 : 30, weight: .medium))
                }
            }
            .frame(
                width: type.isWide ? buttonSize * 2 + spacing : buttonSize,
                height: buttonSize
            )
            .background(type.backgroundColor)
            .foregroundColor(type.foregroundColor)
            .clipShape(
                type.isWide
                    ? AnyShape(Capsule())
                    : AnyShape(Circle())
            )
        }
    }
}

// AnyShape wrapper for conditional shape
struct AnyShape: Shape {
    private let pathBuilder: (CGRect) -> Path

    init<S: Shape>(_ shape: S) {
        pathBuilder = { rect in
            shape.path(in: rect)
        }
    }

    func path(in rect: CGRect) -> Path {
        pathBuilder(rect)
    }
}
