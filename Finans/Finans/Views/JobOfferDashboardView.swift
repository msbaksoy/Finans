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

// MARK: - ADIM 2: ALT BİLEŞENLER (SUB-VIEWS)

/// Şirket A ve Şirket B maaş karşılaştırması — kazananın yanında checkmark, odak karmaşası yok
struct SalaryComparisonRow: View {
    let companyA: String
    let salaryA: Double
    let companyB: String
    let salaryB: Double
    /// true = B kazandı, false = A kazandı, nil = vurgu yok
    let winnerIsB: Bool?
    
    var body: some View {
        HStack(spacing: 20) {
            // Şirket A
            VStack(alignment: .leading, spacing: 8) {
                Text(companyA)
                    .font(.subheadline)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                HStack(spacing: 6) {
                    Text(formatCurrency(salaryA))
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.semibold)
                        .monospacedDigit()
                        .foregroundColor(Color(UIColor.label))
                    if winnerIsB == false {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.subheadline)
                            .foregroundColor(Color(UIColor.systemGreen))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Şirket B
            VStack(alignment: .trailing, spacing: 8) {
                Text(companyB)
                    .font(.subheadline)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                HStack(spacing: 6) {
                    if winnerIsB == true {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.subheadline)
                            .foregroundColor(Color(UIColor.systemGreen))
                    }
                    Text(formatCurrency(salaryB))
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.semibold)
                        .monospacedDigit()
                        .foregroundColor(Color(UIColor.label))
                }
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
                .layoutPriority(1)
            
            Text(companyBValue)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Color(UIColor.label))
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .layoutPriority(1)
        }
        .padding(.vertical, 12)
    }
}

/// Enflasyon etkisi — dinamik veri alır, Apple tipografi standartları (monospacedDigit, rounded), erişilebilir metin
struct InflationImpactCard: View {
    let inflationRate: Int
    let currentSalary: Double
    let futureSalary: Double
    
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
                Image(systemName: "arrow.down.right.circle.fill")
                    .font(.title3)
                    .foregroundColor(Color(UIColor.systemOrange))
                Text("Enflasyon Projeksiyonu")
                    .font(.headline)
                    .foregroundColor(Color(UIColor.label))
            }
            
            VStack(spacing: 8) {
                HStack(alignment: .bottom) {
                    Text("Bugünkü Değer")
                        .font(.subheadline)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .lineLimit(1)
                    Spacer(minLength: 16)
                    Text(formatCurrency(currentSalary))
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.semibold)
                        .strikethrough(true, color: Color(UIColor.systemOrange).opacity(0.8))
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                        .monospacedDigit()
                }
                
                HStack(alignment: .bottom) {
                    Text("12 Ay Sonra")
                        .font(.subheadline)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .lineLimit(1)
                    Spacer(minLength: 16)
                    Text(formatCurrency(futureSalary))
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(Color(UIColor.label))
                        .monospacedDigit()
                }
            }
            .padding(.vertical, 4)
            
            // Kaybedilen miktar rozeti
            if currentSalary > futureSalary {
                Text("- \(formatCurrency(currentSalary - futureSalary)) Kayıp")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(UIColor.systemOrange).opacity(0.15))
                    .foregroundColor(Color(UIColor.systemOrange))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            
            Text("Beklenen %\(inflationRate) enflasyon ile alım gücünüzdeki tahmini erime.")
                .font(.caption)
                .foregroundColor(Color(UIColor.secondaryLabel))
                .fixedSize(horizontal: false, vertical: true)
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
                VStack(alignment: .leading, spacing: 16) {
                    // Maaş Karşılaştırması
                    SalaryComparisonRow(
                        companyA: mockCompanyA,
                        salaryA: mockSalaryA,
                        companyB: mockCompanyB,
                        salaryB: mockSalaryB,
                        winnerIsB: true
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
                    
                    // Enflasyon Kartı — dinamik: currentSalary, futureSalary dışarıdan verilir
                    InflationImpactCard(
                        inflationRate: mockInflationRate,
                        currentSalary: mockTodayValue,
                        futureSalary: mockFutureValue
                    )
                    .modifier(PremiumCardModifier())
                    
                    Spacer(minLength: 32)
                    
                    // CTA Butonu — premium gradient, haptic feedback, yumuşak gölge
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        // Yeni karşılaştırma aksiyonu
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "wand.and.stars")
                            Text("Yapay Zeka ile Analiz Et")
                                .fontWeight(.bold)
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.accentColor.opacity(0.3), radius: 10, x: 0, y: 6)
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
