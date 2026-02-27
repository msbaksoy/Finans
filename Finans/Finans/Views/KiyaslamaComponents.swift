import SwiftUI

/// Small reusable button for work model selection used across Kıyaslama akışı.
struct WorkModelButton: View {
    @EnvironmentObject var appTheme: AppTheme
    let model: WorkModel
    let selected: Bool
    let selectedColors: [Color]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(appTheme.cardBackgroundSecondary)
                if selected {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: selectedColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                VStack(spacing: 6) {
                    Image(systemName: model.icon)
                        .font(.title2)
                        .imageScale(.large)
                    Text(model.displayName)
                        .font(AppTypography.caption2)
                }
                .foregroundColor(selected ? .white : appTheme.textPrimary)
            }
            .frame(minWidth: 64, minHeight: 64)
            .padding(4)
        }
        .buttonStyle(.plain)
    }
}

/// Ulaşım seçeneği butonu — Kıyaslama yol süresi adımında kullanılır.
struct TransportOptionButton: View {
    @EnvironmentObject var appTheme: AppTheme
    let method: TransportMethod
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(appTheme.cardBackgroundSecondary)
                if selected {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "F3F4F6"), Color(hex: "E5E7EB")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .opacity(0.95)
                }
                VStack(spacing: 6) {
                    Image(systemName: method.icon)
                        .font(.title2)
                    Text(method.displayName)
                        .font(AppTypography.caption2)
                }
                .foregroundColor(selected ? Color.white : appTheme.textPrimary)
                .padding(8)
            }
            .frame(minWidth: 78, minHeight: 64)
        }
        .buttonStyle(.plain)
    }
}

/// Simple inline comparison chart used in Kıyaslama analiz ekranı.
struct SimpleInlineChart: View {
    @EnvironmentObject var appTheme: AppTheme
    let current: [Double]
    let offer: [Double]
    let currentColor: Color
    let offerColor: Color
    private let months = ["Oca","Şub","Mar","Nis","May","Haz","Tem","Ağu","Eyl","Eki","Kas","Ara"]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let paddingX: CGFloat = 20
            let chartW = max(0, w - paddingX * 2)
            let maxVal = max((current.max() ?? 1), (offer.max() ?? 1), 1)

            ZStack {
                // offer line (new offer = purple)
                Path { path in
                    for (i, val) in offer.enumerated() {
                        let x = paddingX + (chartW) * CGFloat(i) / 11.0
                        let y = (h - 32) * (1 - CGFloat(val / maxVal)) + 8
                        if i == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(offerColor, lineWidth: 1.0)

                // current line (existing job = blue)
                Path { path in
                    for (i, val) in current.enumerated() {
                        let x = paddingX + (chartW) * CGFloat(i) / 11.0
                        let y = (h - 32) * (1 - CGFloat(val / maxVal)) + 8
                        if i == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(currentColor, lineWidth: 1.0)

                // month labels
                HStack(spacing: 0) {
                    ForEach(0..<12, id: \.self) { i in
                        Text(months[i])
                            .font(AppTypography.caption1.italic())
                            .foregroundColor(appTheme.textSecondary)
                            .rotationEffect(.degrees(-18))
                            .frame(width: chartW / 12, alignment: .center)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 4)
            }
        }
    }
}

/// Compact money input without top label — used in Kıyaslama maaş kartları.
struct CompactMoneyField: View {
    @EnvironmentObject var appTheme: AppTheme
    @Binding var text: String
    var placeholder: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(placeholder)
                .font(AppTypography.caption1)
                .foregroundColor(appTheme.textSecondary)
            FormattedNumberField(
                text: $text,
                placeholder: placeholder,
                allowDecimals: false,
                focusTrigger: .constant(false),
                fontSize: 16,
                fontWeight: .regular,
                isLightMode: appTheme.isLight
            )
            .frame(height: 42)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(appTheme.cardBackgroundSecondary)
            )
        }
    }
}

