import SwiftUI
import Charts

private struct SalaryData: Identifiable {
    let id = UUID()
    let month: Int
    let amount: Double
    let type: String
}

// fixed-size months array to avoid ForEach overload ambiguity
fileprivate let MonthlySalaryMonths: [Int] = Array(0..<12)

struct MonthlySalaryProjectionChart: View {
    let comparison: JobComparison
    @State private var selectedMonth: Int? = nil
    @EnvironmentObject var appTheme: AppTheme

    private let monthLabels = ["Oca","Şub","Mar","Nis","May","Haz","Tem","Ağu","Eyl","Eki","Kas","Ara"]

    private var currentSeries: [SalaryData] {
        Array(zip(1..., comparison.currentMonthlyNet).map { month, amt in SalaryData(month: month, amount: amt, type: "Mevcut") })
    }
    private var offerSeries: [SalaryData] {
        Array(zip(1..., comparison.offerMonthlyNet).map { month, amt in SalaryData(month: month, amount: amt, type: "Teklif") })
    }

    private var yDomain: ClosedRange<Double> {
        let all = (comparison.currentMonthlyNet + comparison.offerMonthlyNet)
        guard let minVal = all.min(), let maxVal = all.max() else { return 0...1 }
        let pad = Swift.max( (maxVal - minVal) * 0.06, maxVal * 0.02 )
        return Swift.max(0, minVal - pad)...(maxVal + pad)
    }

    var body: some View {
        // compute once to simplify view-builder complexity
        let maxVal = (comparison.currentMonthlyNet + comparison.offerMonthlyNet).max() ?? 1
        return VStack(alignment: .leading, spacing: 12) {
            // Simplified and performant monthly bar projection (two bars per month)
            HStack(alignment: .bottom, spacing: 6) {
                // explicit 12 bars to avoid ForEach overload ambiguity on some toolchains
                barView(0, maxVal: maxVal); barView(1, maxVal: maxVal); barView(2, maxVal: maxVal); barView(3, maxVal: maxVal)
                barView(4, maxVal: maxVal); barView(5, maxVal: maxVal); barView(6, maxVal: maxVal); barView(7, maxVal: maxVal)
                barView(8, maxVal: maxVal); barView(9, maxVal: maxVal); barView(10, maxVal: maxVal); barView(11, maxVal: maxVal)
            }
            .frame(height: 220)
            
            // Consolidated net salary summary + AI-like comment card
            let currentMonthly = comparison.currentYearlyNetWithBonus / 12.0
            let offerMonthly = comparison.offerYearlyNetWithBonus / 12.0
            let delta = offerMonthly - currentMonthly
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Mevcut (Net / ay)").font(AppTypography.subheadline).foregroundColor(appTheme.textSecondary)
                    Text(FinanceFormatter.currencyString(currentMonthly)).font(AppTypography.amountMedium).monospacedDigit()
                }
                Spacer()
                VStack(alignment: .leading, spacing: 6) {
                    Text("Teklif (Net / ay)").font(AppTypography.subheadline).foregroundColor(appTheme.textSecondary)
                    Text(FinanceFormatter.currencyString(offerMonthly)).font(AppTypography.amountMedium).monospacedDigit()
                }
                Spacer()
                VStack(alignment: .leading, spacing: 6) {
                    Text("Aylık Fark").font(AppTypography.subheadline).foregroundColor(appTheme.textSecondary)
                    Text("\(delta >= 0 ? "+" : "")\(FinanceFormatter.currencyString(delta))")
                        .font(AppTypography.amountMedium)
                        .foregroundColor(delta >= 0 ? Color.green : Color.red)
                        .monospacedDigit()
                }
            }
            .padding(.top, 6)
            
            // AI-like comment consolidated in a card (reuses PremiumCardModifier)
            VStack(alignment: .leading, spacing: 8) {
                Text("Yorum").font(AppTypography.headline).foregroundColor(appTheme.textPrimary)
                Text(comparison.raiseAnalysisString())
                    .font(AppTypography.footnote)
                    .foregroundColor(appTheme.textPrimary)
                Text(comparison.careerImpactString())
                    .font(AppTypography.caption1)
                    .foregroundColor(appTheme.textSecondary)
            }
            .padding(12)
            .modifier(PremiumCardModifier())
            .background(appTheme.listRowBackground)

            HStack(spacing: 16) {
                HStack(spacing: 8) {
                    Circle().stroke(Color.secondary, lineWidth: 1).frame(width:12, height:12)
                    Text("Mevcut").font(AppTypography.subheadline).foregroundColor(appTheme.textSecondary)
                }
                HStack(spacing: 8) {
                    Circle().fill(Color.accentColor).frame(width:12, height:12)
                    Text("Yeni Teklif").font(AppTypography.subheadline).foregroundColor(appTheme.textSecondary)
                }
                Spacer()
            }
        }
        .padding(12)
        .modifier(PremiumCardModifier())
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(14)
    }
}

fileprivate extension MonthlySalaryProjectionChart {
    @ViewBuilder
    func barView(_ idx: Int, maxVal: Double) -> some View {
        let cur = idx < comparison.currentMonthlyNet.count ? comparison.currentMonthlyNet[idx] : 0
        let off = idx < comparison.offerMonthlyNet.count ? comparison.offerMonthlyNet[idx] : 0
        VStack(spacing: 6) {
            if selectedMonth == idx + 1 {
                            VStack(spacing: 4) {
                    Text(shortKString(off))
                        .font(AppTypography.caption1)
                        .monospacedDigit()
                        .italic()
                        .rotationEffect(.degrees(-8))
                    Text(shortKString(cur))
                        .font(AppTypography.caption1)
                        .monospacedDigit()
                        .italic()
                        .rotationEffect(.degrees(-8))
                            }
            }
            HStack(alignment: .bottom, spacing: 4) {
                Rectangle()
                    .fill(Color.secondary.opacity(0.6))
                    .frame(width: 10, height: CGFloat(cur / maxVal) * 140)
                    .cornerRadius(4)
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(width: 10, height: CGFloat(off / maxVal) * 160)
                    .cornerRadius(4)
            }
            .onTapGesture {
                withAnimation { selectedMonth = (selectedMonth == idx + 1) ? nil : (idx + 1) }
            }
            Text(monthLabels[idx])
                .font(AppTypography.caption1)
                .foregroundColor(appTheme.textSecondary)
                .rotationEffect(.degrees(-12))
                .italic()
        }
        .frame(maxWidth: .infinity)
    }
    
    // Shorten currency to K (thousands), rounding to nearest thousand
    func shortKString(_ value: Double) -> String {
        let k = Int((value / 1000.0).rounded())
        return "\(k)K"
    }
}

