import SwiftUI

/// Küresel tasarım bileşenleri: buton stilleri, erişilebilir hit-area ve formatterlar
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [Color(hex: "F59E0B"), Color(hex: "FBBF24")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(16)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
            .shadow(color: Color.black.opacity(configuration.isPressed ? 0 : 0.12), radius: 10, y: 4)
            .accessibilityAddTraits(.isButton)
            .contentShape(Rectangle())
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(hex: "94A3B8").opacity(0.18), lineWidth: 1)
            )
            .foregroundColor(Color(hex: "0F172A"))
            .scaleEffect(configuration.isPressed ? 0.995 : 1)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
            .contentShape(Rectangle())
    }
}

extension View {
    /// Minimum erişilebilir dokunma alanı sağlar (44pt)
    func accessibleHitArea(minSize: CGFloat = 44) -> some View {
        padding(.vertical,  max(0, (minSize - 16) / 2))
            .contentShape(Rectangle())
    }
}

/// Merkezi formatterlar — tek kaynak olmalı
enum FinanceFormatter {
    static let currency: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "tr_TR")
        f.maximumFractionDigits = 0
        f.minimumFractionDigits = 0
        return f
    }()

    static let decimal: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 2
        f.locale = Locale(identifier: "tr_TR")
        return f
    }()

    static func currencyString(_ value: Double) -> String {
        currency.string(from: NSNumber(value: value)) ?? "₺0"
    }

    static func decimalString(_ value: Double) -> String {
        decimal.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

