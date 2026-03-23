import SwiftUI
import UIKit

/// Labeled numeric text field with optional thousands formatting — Kıyaslama prim, Mevduat formu.
struct KrediTextField: View {
    @EnvironmentObject var appTheme: AppTheme
    let title: String
    @Binding var text: String
    var placeholder: String = ""
    var formatThousands: Bool = true
    var suffix: String? = nil
    var allowDecimals: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppTypography.caption1)
                .foregroundColor(appTheme.textSecondary)
            HStack(alignment: .center, spacing: 8) {
                if formatThousands {
                    FormattedNumberField(
                        text: $text,
                        placeholder: placeholder,
                        allowDecimals: allowDecimals,
                        focusTrigger: .constant(false),
                        fontSize: 16,
                        fontWeight: .regular,
                        isLightMode: appTheme.isLight
                    )
                    .frame(height: 42)
                    .padding(.horizontal, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(appTheme.formInputBackground)
                    )
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(allowDecimals ? .decimalPad : .numberPad)
                        .font(.body.monospacedDigit())
                        .foregroundColor(appTheme.textPrimary)
                        .frame(height: 42)
                        .padding(.horizontal, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(appTheme.formInputBackground)
                        )
                }
                if let suffix = suffix {
                    Text(suffix)
                        .font(AppTypography.subheadline)
                        .foregroundColor(appTheme.textSecondary)
                }
            }
        }
    }
}

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
                    Image(systemName: method.icon)
                        .font(.title2)
                        .imageScale(.large)
                    Text(method.displayName)
                        .font(AppTypography.caption2)
                }
                .foregroundColor(selected ? .white : appTheme.textPrimary)
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

// MARK: - LIVE WEALTH TICKER (Gerçek Zamanlı Fark Sayacı)
struct LiveWealthTicker: View {
    @ObservedObject var viewModel: KariyerKiyaslamaViewModel
    @EnvironmentObject var appTheme: AppTheme

    var body: some View {
        let m1_Yalin = viewModel.calculateNet(isCurrent: true, includePrim: false).yillikNet
        let m2_Yalin = viewModel.calculateNet(isCurrent: false, includePrim: false).yillikNet
        let m1_Prim = viewModel.calculateNet(isCurrent: true, includePrim: true).yillikNet - m1_Yalin
        let m2_Prim = viewModel.calculateNet(isCurrent: false, includePrim: true).yillikNet - m2_Yalin
        let m1_Gizli = viewModel.calculateHiddenWealth(isCurrent: true)
        let m2_Gizli = viewModel.calculateHiddenWealth(isCurrent: false)

        let mevcutTotal = m1_Yalin + m1_Prim + m1_Gizli
        let teklifTotal = m2_Yalin + m2_Prim + m2_Gizli
        let fark = teklifTotal - mevcutTotal

        let isPositive = fark >= 0
        let displayColor = fark == 0 ? Color.gray : (isPositive ? Color.green : Color.red)
        let iconName = fark == 0 ? "minus.circle.fill" : (isPositive ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")

        let farkStr: String = {
            let f = NumberFormatter()
            f.numberStyle = .currency
            f.currencySymbol = "₺"
            f.maximumFractionDigits = 0
            return f.string(from: NSNumber(value: abs(fark))) ?? "₺0"
        }()

        HStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.system(size: 16, weight: .bold))

            Text(fark == 0 ? "Fark Hesaplanıyor..." : (isPositive ? "+\(farkStr) Kâr" : "-\(farkStr) Zarar"))
                .font(.system(.subheadline, design: .rounded).weight(.heavy))
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(displayColor.opacity(0.15))
        .foregroundColor(displayColor)
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(displayColor.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: displayColor.opacity(0.2), radius: 8, y: 4)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: fark)
    }
}

// MARK: - Dev Anket Butonu (Büyük Dokunma Alanı)
struct SurveyOptionCard: View {
    @EnvironmentObject var appTheme: AppTheme
    let title: String
    let subtitle: String?
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        }) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(isSelected ? appTheme.primaryAccent : Color.gray.opacity(0.1))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.body.bold())
                        .foregroundColor(isSelected ? .white : appTheme.primaryAccent)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(isSelected ? appTheme.primaryAccent : appTheme.textPrimary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(nil)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Spacer(minLength: 8)

                ZStack {
                    Circle()
                        .stroke(isSelected ? appTheme.primaryAccent : Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    if isSelected {
                        Circle()
                            .fill(appTheme.primaryAccent)
                            .frame(width: 14, height: 14)
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(isSelected ? appTheme.primaryAccent.opacity(0.05) : Color(uiColor: .systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(isSelected ? appTheme.primaryAccent : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: isSelected ? appTheme.primaryAccent.opacity(0.15) : .black.opacity(0.02), radius: 10, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
}

// MARK: - Şelale Logo Motoru (Clearbit → DuckDuckGo → Icon.horse → Google → Monogram)
struct CompanyLogoWaterfall: View {
    let domain: String
    let name: String
    let size: CGFloat
    let appTheme: AppTheme
    @State private var attempt = 0 // 0: Clearbit, 1: DuckDuckGo, 2: Icon.horse, 3: Google, 4: Monogram

    var body: some View {
        Group {
            if attempt == 0 {
                AsyncImage(url: URL(string: "https://logo.clearbit.com/\(domain)")) { phase in
                    handlePhase(phase, nextAttempt: 1)
                }
            } else if attempt == 1 {
                AsyncImage(url: URL(string: "https://icons.duckduckgo.com/ip3/\(domain).ico")) { phase in
                    handlePhase(phase, nextAttempt: 2)
                }
            } else if attempt == 2 {
                AsyncImage(url: URL(string: "https://icon.horse/icon/\(domain)")) { phase in
                    handlePhase(phase, nextAttempt: 3)
                }
            } else if attempt == 3 {
                let encoded = domain.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? domain
                AsyncImage(url: URL(string: "https://www.google.com/s2/favicons?sz=128&domain=\(encoded)")) { phase in
                    handlePhase(phase, nextAttempt: 4)
                }
            } else {
                monogramView
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.2))
    }

    @ViewBuilder
    private func handlePhase(_ phase: AsyncImagePhase, nextAttempt: Int) -> some View {
        if let image = phase.image {
            image.resizable().scaledToFit()
        } else if phase.error != nil {
            Color.clear.onAppear { attempt = nextAttempt }
        } else {
            ProgressView().scaleEffect(0.5)
        }
    }

    private var monogramView: some View {
        ZStack {
            LinearGradient(
                colors: [appTheme.primaryAccent.opacity(0.8), appTheme.secondaryAccent.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Text(String(name.prefix(1)).uppercased())
                .font(.system(size: size * 0.5, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Akıllı Şirket Arama (Şelale logo: Clearbit → Icon.horse → Google → Monogram)
struct CompanyAutocompleteField: View {
    @EnvironmentObject var appTheme: AppTheme
    var placeholder: String
    @Binding var text: String

    @StateObject private var searchService = CompanySearchService()
    @State private var showSuggestions = false
    @FocusState private var isFocused: Bool
    @State private var selectedDomain: String? = nil
    @State private var selectedName: String = ""

    /// Clearbit'te çıkmasa bile yazıdan tahmini .com.tr domain üretir
    private func guessedDomain(from query: String) -> String? {
        var q = query.lowercased()
        let stopWords = [" bankası", " bankasi", " katılım", " katilim", " a.ş.", " a.ş", " anonim", " şirketi", " sirketi", " ltd", " şti", " sti", " sanayi", " ticaret", " holding", " grubu", " vakfı", " vakfi"]
        for w in stopWords { q = q.replacingOccurrences(of: w, with: "") }
        q = q.trimmingCharacters(in: .whitespaces)
        let turkishToAscii: [(String, String)] = [("ı", "i"), ("ş", "s"), ("ğ", "g"), ("ü", "u"), ("ö", "o"), ("ç", "c")]
        for (t, a) in turkishToAscii { q = q.replacingOccurrences(of: t, with: a) }
        let slug = q.filter { $0.isLetter || $0.isNumber }.lowercased()
        guard slug.count >= 2 else { return nil }
        return "\(slug).com.tr"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                if let domain = selectedDomain, !text.isEmpty {
                    CompanyLogoWaterfall(domain: domain, name: selectedName.isEmpty ? text : selectedName, size: 28, appTheme: appTheme)
                } else if !searchService.searchQuery.isEmpty, let guessed = guessedDomain(from: searchService.searchQuery) {
                    CompanyLogoWaterfall(domain: guessed, name: searchService.searchQuery, size: 28, appTheme: appTheme)
                } else {
                    Image(systemName: "building.2.fill")
                        .foregroundColor(.gray.opacity(0.5))
                        .frame(width: 28, height: 28)
                }

                TextField(placeholder, text: $searchService.searchQuery)
                    .focused($isFocused)
                    .font(.body.weight(.medium))
                    .onChange(of: searchService.searchQuery) { _, newValue in
                        text = newValue
                        showSuggestions = !newValue.isEmpty
                        if newValue.isEmpty {
                            selectedDomain = nil
                            selectedName = ""
                        }
                        matchQueryToSuggestion()
                    }
                if searchService.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(appTheme.primaryAccent)
                } else {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray.opacity(0.5))
                }
            }
            .padding(12)
            .background(Color.gray.opacity(0.08))
            .cornerRadius(12)

            if showSuggestions && !searchService.suggestions.isEmpty && isFocused {
                VStack(spacing: 0) {
                    ForEach(searchService.suggestions.prefix(4)) { company in
                        Button(action: {
                            text = company.name
                            searchService.searchQuery = company.name
                            selectedDomain = company.domain
                            selectedName = company.name
                            showSuggestions = false
                            isFocused = false
                        }) {
                            HStack(spacing: 12) {
                                CompanyLogoWaterfall(domain: company.domain, name: company.name, size: 32, appTheme: appTheme)
                                Text(company.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(appTheme.textPrimary)
                                    .lineLimit(1)
                                Spacer(minLength: 8)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 14)
                            .background(Color(uiColor: .systemBackground))
                        }
                        .buttonStyle(.plain)
                        Divider().padding(.horizontal, 14)
                    }
                }
                .background(Color(uiColor: .systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .onAppear {
            if !text.isEmpty {
                searchService.searchQuery = text
                selectedName = text
            }
            matchQueryToSuggestion()
        }
        .onChange(of: searchService.suggestions) { _, _ in
            matchQueryToSuggestion()
        }
    }

    private func matchQueryToSuggestion() {
        let q = searchService.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty, let match = searchService.suggestions.first(where: { $0.name == q }) else { return }
        selectedDomain = match.domain
        selectedName = match.name
    }
}

