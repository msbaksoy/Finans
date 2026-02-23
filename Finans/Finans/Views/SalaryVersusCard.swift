import SwiftUI

struct SalaryVersusCard: View {
    let currentNet: Double
    let offeredNet: Double
    @EnvironmentObject var appTheme: AppTheme
    @Environment(\.horizontalSizeClass) private var hSizeClass

    private var maxValue: Double { max(currentNet, offeredNet, 1) }
    private var diff: Double { offeredNet - currentNet }

    var body: some View {
        GeometryReader { full in
            let compact = (hSizeClass == .compact) || full.size.width < 360
            let barHeight: CGFloat = compact ? 84 : 120
            let hSpacing: CGFloat = compact ? 12 : 24
            let outerPadding: CGFloat = compact ? 12 : 16
            VStack(spacing: compact ? 10 : 16) {
                HStack(alignment: .bottom, spacing: hSpacing) {
                    // Current
                    CompactBar(
                        value: currentNet,
                        maxValue: maxValue,
                        label: "Mevcut",
                        valueFont: compact ? AppTypography.amountMedium : AppTypography.amountLarge,
                        barHeight: barHeight,
                        barColor: appTheme.cardBackgroundSecondary,
                        strokeColor: appTheme.cardStroke,
                        textColor: appTheme.textPrimary,
                        captionColor: appTheme.textSecondary,
                        cornerRadius: compact ? 6 : 8
                    )
                    // Offered
                    CompactBar(
                        value: offeredNet,
                        maxValue: maxValue,
                        label: "Teklif",
                        valueFont: compact ? AppTypography.amountMedium : AppTypography.amountLarge,
                        barHeight: barHeight,
                        barColor: Color.accentColor,
                        strokeColor: appTheme.cardStroke,
                        textColor: appTheme.textPrimary,
                        captionColor: appTheme.textSecondary,
                        cornerRadius: compact ? 6 : 8,
                        isOffered: true
                    )
                }

                // Difference box (compact)
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Yıllık Toplam Fark")
                            .font(AppTypography.subheadline)
                            .foregroundColor(appTheme.textSecondary)
                        Text("\(FinanceFormatter.currencyString(abs(diff * 12))). \(diff >= 0 ? \"Artış\" : \"Azalış\")")
                            .font(compact ? AppTypography.amountMedium : AppTypography.amountMedium)
                            .foregroundColor(diff >= 0 ? Color(hex: "16A34A") : Color(hex: "EF4444"))
                            .monospacedDigit()
                    }
                    Spacer()
                    Text(String(format: "%+.1f%%", (offeredNet - currentNet) / maxValue * 100))
                        .font(AppTypography.subheadline)
                        .foregroundColor(appTheme.textSecondary)
                }
                .padding(compact ? 10 : 12)
                .modifier(PremiumCardModifier())
            }
            .padding(outerPadding)
            .background(appTheme.cardBackground)
            .cornerRadius(compact ? 12 : 14)
        }
        .frame(height:  (hSizeClass == .compact) ? 220 : 300)
    }
}

private struct CompactBar: View {
    let value: Double
    let maxValue: Double
    let label: String
    let valueFont: Font
    let barHeight: CGFloat
    let barColor: Color
    let strokeColor: Color
    let textColor: Color
    let captionColor: Color
    let cornerRadius: CGFloat
    var isOffered: Bool = false

    var body: some View {
        VStack(spacing: 8) {
            Text(FinanceFormatter.currencyString(value))
                .font(valueFont)
                .foregroundColor(Color(textColor))
                .monospacedDigit()
            GeometryReader { geo in
                let height = geo.size.height
                let barH = CGFloat(value / maxValue) * height
                VStack {
                    Spacer(minLength: 0)
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(barColor)
                        .frame(height: max(isOffered ? 8 : 6, barH * (isOffered ? 1.03 : 1.0)))
                        .if(isOffered) { view in
                            view.shadow(color: Color.accentColor.opacity(0.16), radius: 6, x: 0, y: 4)
                        }
                        .overlay(RoundedRectangle(cornerRadius: cornerRadius).stroke(strokeColor.opacity(0.12)))
                }
            }
            .frame(height: barHeight)
            Text(label)
                .font(AppTypography.subheadline)
                .foregroundColor(captionColor)
        }
        .frame(maxWidth: .infinity)
    }
}

// Small View extension helper for conditional modifier
fileprivate extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

#Preview {
    SalaryVersusCard(currentNet: 85000, offeredNet: 98000)
        .environmentObject(AppTheme())
}

