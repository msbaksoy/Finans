import SwiftUI

// MARK: - Formatted number input (TR: binlik ayırıcı, ondalık virgül)

struct FormattedNumberField: View {
    @Binding var text: String
    var placeholder: String
    var allowDecimals: Bool
    @Binding var focusTrigger: Bool
    var fontSize: CGFloat = 16
    var fontWeight: Font.Weight = .regular
    var isLightMode: Bool
    var onCommit: (() -> Void)? = nil

    @FocusState private var focused: Bool

    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(allowDecimals ? .decimalPad : .numberPad)
            .font(.system(size: fontSize, weight: fontWeight))
            .focused($focused)
            .onChange(of: text) { _, newValue in
                let cleaned = newValue
                    .replacingOccurrences(of: ".", with: "")
                    .replacingOccurrences(of: ",", with: ".")
                if let d = Double(cleaned) {
                    let formatted = formatNumberGiris(String(format: allowDecimals ? "%.2f" : "%.0f", d), allowDecimals: allowDecimals)
                    if formatted != newValue {
                        text = formatted
                    }
                }
            }
            .onChange(of: focusTrigger) { _, newValue in
                if newValue {
                    focused = true
                    focusTrigger = false
                }
            }
            .onSubmit {
                onCommit?()
            }
    }
}

// MARK: - Tap to focus modifier (FocusState ve Binding ile uyumlu)

extension View {
    /// Tıklanınca focus’u tetiklemek için (örn. `@FocusState var f: Bool` → `.tappableToFocus { f = true }`).
    func tappableToFocus(perform action: @escaping () -> Void) -> some View {
        contentShape(Rectangle())
            .onTapGesture(perform: action)
    }
}
