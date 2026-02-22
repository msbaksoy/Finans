import SwiftUI

// MARK: - ADIM 1: TASARIM SİSTEMİ (DESIGN SYSTEM)

/// Premium kart görünümü — secondarySystemGroupedBackground, 20pt corner radius, yumuşak gölge
struct PremiumCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 6)
    }
}

/// Kazanan teklifi gösteren yeşil tonlarında rozet
struct WinnerBadgeView: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(Color(UIColor.systemBackground))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(UIColor.systemGreen),
                                Color(UIColor.systemGreen).opacity(0.85)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
    }
}

// MARK: - ADIM 2: ALT BİLEŞENLER (SUB-VIEWS)

/// Şirket A ve Şirket B maaş karşılaştırması — ortada WinnerBadgeView
struct SalaryComparisonRow: View {
    let companyA: String
    let salaryA: Double
    let companyB: String
    let salaryB: Double
    let winnerText: String?
    
    var body: some View {
        HStack(spacing: 16) {
            // Şirket A
            VStack(alignment: .leading, spacing: 8) {
                Text(companyA)
                    .font(.subheadline)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                Text(formatCurrency(salaryA))
                    .font(.headline)
                    .monospacedDigit()
                    .foregroundColor(Color(UIColor.label))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Kazanan rozeti
            if let winner = winnerText {
                WinnerBadgeView(text: winner)
            }
            
            // Şirket B
            VStack(alignment: .trailing, spacing: 8) {
                Text(companyB)
                    .font(.subheadline)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                Text(formatCurrency(salaryB))
                    .font(.headline)
                    .monospacedDigit()
                    .foregroundColor(Color(UIColor.label))
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(24)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = "."
        formatter.decimalSeparator = ","
        return "\(formatter.string(from: NSNumber(value: value)) ?? "—") ₺"
    }
}

/// Yan hak detay satırı — SF Symbols ikonlu, simetrik hizalama (uzun metinlerde dağılma yok)
struct BenefitDetailRow: View {
    let icon: String
    let title: String
    let companyAValue: String
    let companyBValue: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(.tint)
                .frame(width: 32, alignment: .center)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(Color(UIColor.secondaryLabel))
                .frame(width: 72, alignment: .leading)
            
            Text(companyAValue)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Color(UIColor.label))
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(companyBValue)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Color(UIColor.label))
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 12)
    }
}

/// Enflasyon etkisi — bilişsel yükü düşüren, taranabilir görsel sunum (saf kırmızı yok)
struct InflationImpactCard: View {
    let todayValue: Double
    let futureValue: Double
    let inflationRate: Int
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = "."
        formatter.decimalSeparator = ","
        return "₺\(formatter.string(from: NSNumber(value: value)) ?? "—")"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "chart.line.downtrend.xyaxis")
                    .font(.title3)
                    .foregroundColor(Color.orange.opacity(0.9))
                Text("Enflasyon Projeksiyonu")
                    .font(.headline)
                    .foregroundColor(Color(UIColor.label))
            }
            
            HStack(alignment: .bottom) {
                Text("Bugünkü Değer:")
                    .font(.subheadline)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                Spacer()
                Text(formatCurrency(todayValue))
                    .font(.title3)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .strikethrough(true, color: Color.orange.opacity(0.6))
                    .foregroundColor(Color(UIColor.tertiaryLabel))
            }
            
            HStack(alignment: .bottom) {
                Text("12 Ay Sonra Alım Gücü:")
                    .font(.subheadline)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                Spacer()
                Text(formatCurrency(futureValue))
                    .font(.title2)
                    .fontWeight(.bold)
                    .monospacedDigit()
                    .foregroundColor(Color(UIColor.label))
            }
            
            Text("Beklenen %\(inflationRate) enflasyon ile alım gücünüzdeki tahmini erime.")
                .font(.caption2)
                .foregroundColor(Color(UIColor.secondaryLabel))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
    }
}

// MARK: - ADIM 3: ANA EKRAN (MAIN VIEW)

struct JobOfferDashboardView: View {
    
    // Mock Data
    private let mockCompanyA = "Mevcut İş Yeri"
    private let mockCompanyB = "Teklif Edilen"
    private let mockSalaryA: Double = 85_000
    private let mockSalaryB: Double = 98_000
    private let mockBenefits: [(icon: String, title: String, valueA: String, valueB: String)] = [
        ("shield.fill", "Sigorta", "ÖSS, Aile Kapsamlı", "TSS + ÖSS, Aile Kapsamlı"),
        ("fork.knife", "Yemek", "Yemek Kartı 150₺/gün", "Yemekhane + Yemek Kartı"),
        ("laptopcomputer", "Çalışma Modeli", "Hibrit (3 gün ofis)", "Remote (Tam uzaktan)")
    ]
    private let mockInflationRate = 45
    private var mockTodayValue: Double { mockSalaryA }
    private var mockFutureValue: Double { mockSalaryA / (1 + Double(mockInflationRate) / 100) }
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Maaş Karşılaştırması
                    SalaryComparisonRow(
                        companyA: mockCompanyA,
                        salaryA: mockSalaryA,
                        companyB: mockCompanyB,
                        salaryB: mockSalaryB,
                        winnerText: "%15 Daha İyi"
                    )
                    .modifier(PremiumCardModifier())
                    
                    // Yan Haklar
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Yan Haklar")
                            .font(.headline)
                            .foregroundColor(Color(UIColor.label))
                            .padding(.horizontal, 24)
                            .padding(.top, 24)
                        
                        // Tablo başlıkları — Mevcut İş | Teklif
                        HStack(spacing: 16) {
                            Spacer().frame(width: 32)
                            Spacer().frame(width: 72)
                            Text("Mevcut İş")
                                .font(.caption2)
                                .foregroundColor(Color(UIColor.tertiaryLabel))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("Teklif")
                                .font(.caption2)
                                .foregroundColor(Color(UIColor.tertiaryLabel))
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .padding(.horizontal, 16)
                        
                        VStack(spacing: 0) {
                            ForEach(Array(mockBenefits.enumerated()), id: \.offset) { _, benefit in
                                BenefitDetailRow(
                                    icon: benefit.icon,
                                    title: benefit.title,
                                    companyAValue: benefit.valueA,
                                    companyBValue: benefit.valueB
                                )
                            }
                        }
                        .padding(.bottom, 16)
                    }
                    .modifier(PremiumCardModifier())
                    
                    // Enflasyon Kartı
                    InflationImpactCard(
                        todayValue: mockTodayValue,
                        futureValue: mockFutureValue,
                        inflationRate: mockInflationRate
                    )
                    .modifier(PremiumCardModifier())
                    
                    Spacer(minLength: 32)
                    
                    // CTA Butonu — premium gradient, sparkles ikonu, yumuşak gölge
                    Button {
                        // Yeni karşılaştırma aksiyonu
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                            Text("Yapay Zeka ile Analiz Et")
                                .fontWeight(.bold)
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "007AFF"), Color(hex: "005BB5")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color(hex: "007AFF").opacity(0.3), radius: 10, x: 0, y: 6)
                    }
                    .buttonStyle(.plain)
                }
                .padding(24)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Teklif Analizi")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        JobOfferDashboardView()
    }
}
