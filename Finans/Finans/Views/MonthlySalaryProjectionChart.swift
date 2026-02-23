import SwiftUI
import Charts

private struct SalaryData: Identifiable {
    let id = UUID()
    let month: Int
    let amount: Double
    let type: String
}

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
        VStack(alignment: .leading, spacing: 12) {
            Chart {
                ForEach(offerSeries) { p in
                    AreaMark(x: .value("Ay", p.month), y: .value("Miktar", p.amount))
                        .foregroundStyle(LinearGradient(colors: [Color.accentColor.opacity(0.22), Color.accentColor.opacity(0.05)], startPoint: .top, endPoint: .bottom))
                }
                ForEach(offerSeries) { p in
                    LineMark(x: .value("Ay", p.month), y: .value("Miktar", p.amount))
                        .interpolationMethod(.cardinal)
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                        .foregroundStyle(LinearGradient(colors: [Color(hex: "3B82F6"), Color(hex: "4F46E5")], startPoint: .leading, endPoint: .trailing))
                }
                ForEach(currentSeries) { p in
                    AreaMark(x: .value("Ay", p.month), y: .value("Miktar", p.amount))
                        .foregroundStyle(Color.secondary.opacity(0.06))
                }
                ForEach(currentSeries) { p in
                    LineMark(x: .value("Ay", p.month), y: .value("Miktar", p.amount))
                        .interpolationMethod(.cardinal)
                        .lineStyle(StrokeStyle(lineWidth: 1.25, dash: [6,4], lineCap: .round))
                        .foregroundStyle(Color.secondary)
                }
            }
            .chartYScale(domain: yDomain)
            .chartXAxis {
                AxisMarks(values: Array(1...12)) { idx in
                    AxisValueLabel {
                        if let v = idx.as(Int.self), v >= 1 && v <= 12 {
                            Text(monthLabels[v-1]).font(AppTypography.caption).foregroundColor(appTheme.textSecondary)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { mark in
                    AxisValueLabel {
                        if let value = mark.as(Double.self) {
                            Text(FinanceFormatter.currencyString(value)).font(AppTypography.caption).foregroundColor(appTheme.textSecondary)
                        }
                    }
                }
            }
            .frame(height: 220)
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle().fill(Color.clear).contentShape(Rectangle())
                        .gesture(DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let location = value.location
                                if let monthValue: Int = proxy.value(atX: location.x) as? Int {
                                    selectedMonth = min(max(monthValue, 1), 12)
                                }
                            }
                            .onEnded { _ in
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation(.easeOut) { selectedMonth = nil }
                                }
                            }
                        )

                    if let month = selectedMonth, let xPos = proxy.position(forX: month) {
                        let idx = month - 1
                        let cur = comparison.currentMonthlyNet.indices.contains(idx) ? comparison.currentMonthlyNet[idx] : 0
                        let off = comparison.offerMonthlyNet.indices.contains(idx) ? comparison.offerMonthlyNet[idx] : 0
                        VStack(spacing: 6) {
                            Text(monthLabels[idx]).font(AppTypography.subheadline).foregroundColor(appTheme.textPrimary)
                            HStack(spacing: 12) {
                                HStack(spacing:6) {
                                    Circle().stroke(Color.secondary, lineWidth: 1).frame(width:10, height:10)
                                    Text("Mevcut:").font(AppTypography.caption).foregroundColor(appTheme.textSecondary)
                                    Text(FinanceFormatter.currencyString(cur)).font(AppTypography.subheadline).monospacedDigit()
                                }
                                HStack(spacing:6) {
                                    Circle().fill(Color.accentColor).frame(width:10, height:10)
                                    Text("Teklif:").font(AppTypography.caption).foregroundColor(appTheme.textSecondary)
                                    Text(FinanceFormatter.currencyString(off)).font(AppTypography.subheadline).monospacedDigit()
                                }
                            }
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 10).fill(appTheme.cardBackgroundSecondary))
                            .shadow(radius: 6, y: 4)
                        }
                        .position(x: xPos, y: 40)
                    }
                }
            }
            .animation(.easeOut(duration: 1.0), value: currentSeries)

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

