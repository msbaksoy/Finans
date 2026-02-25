import Foundation

/// Central comparison engine used by Kıyaslama and Dashboard features.
/// Builds on existing YanHakVerisi and BrutNetCalculator to produce
/// monthly net series, yearly totals and summary metrics.
struct JobComparison {
    let current: YanHakVerisi
    let offer: YanHakVerisi

    // MARK: - Monthly net series (12 elements)
    var currentMonthlyNet: [Double] {
        nets(for: current)
    }

    var offerMonthlyNet: [Double] {
        nets(for: offer)
    }

    private func nets(for v: YanHakVerisi) -> [Double] {
        guard v.brutMaas > 0 else {
            // If no brut provided but net expected, use yillikNetMaas/12
            let aylik = v.yillikNetMaas / 12.0
            return Array(repeating: aylik, count: 12)
        }
        // Effective monthly brut accounting for maasPeriyodu > 12
        let efektif = v.maasPeriyodu > 12 ? (Double(v.maasPeriyodu) * v.brutMaas / 12.0) : v.brutMaas
        let brutlar = Array(repeating: efektif, count: 12)
        // Prim: if provided as annual net value it's handled elsewhere; YanHakVerisi stores prim as annual net expectation
        let primAnnual = v.yillikPrimBonusTutar ?? 0
        let primler = Array(repeating: primAnnual / 12.0, count: 12)
        let sonuc = BrutNetCalculator.hesaplaYillik(brutlar: brutlar, primler: primler)
        return sonuc.map { $0.net }
    }

    // MARK: - Aggregates
    var currentAnnualNet: Double { currentMonthlyNet.reduce(0, +) }
    var offerAnnualNet: Double { offerMonthlyNet.reduce(0, +) }

    var currentMonthlyAverageNet: Double { currentAnnualNet / 12.0 }
    var offerMonthlyAverageNet: Double { offerAnnualNet / 12.0 }

    var annualNetDifference: Double { offerAnnualNet - currentAnnualNet }
    var monthlyNetDifference: Double { offerMonthlyAverageNet - currentMonthlyAverageNet }
    var raisePercent: Double {
        guard currentAnnualNet > 0 else { return 0 }
        return (offerAnnualNet - currentAnnualNet) / currentAnnualNet * 100
    }

    // MARK: - Life quality / commute
    var currentWeeklyCommuteMinutes: Int { (current.commuteTimeInMinutes ?? 0) * current.officeDaysPerWeek * 1 }
    var offerWeeklyCommuteMinutes: Int { (offer.commuteTimeInMinutes ?? 0) * offer.officeDaysPerWeek * 1 }
    var weeklyCommuteSavedMinutes: Int { max(0, currentWeeklyCommuteMinutes - offerWeeklyCommuteMinutes) }

    var annualLostDaysSaved: Double {
        Double(weeklyCommuteSavedMinutes) * 52.0 / 60.0 / 24.0
    }

    // MARK: - Total compensation (net basis)
    var currentTotalCompensationNet: Double { currentAnnualNet }
    var offerTotalCompensationNet: Double { offerAnnualNet }

    // MARK: - AI-friendly summary strings (simple heuristics)
    func raiseAnalysisString() -> String {
        let p = raisePercent
        if p < 5 { return "Finansal olarak önemsiz bir değişim." }
        if p < 15 { return "Makul ve kabul edilebilir bir artış." }
        if p < 30 { return "Güçlü bir finansal sıçrama." }
        return "Mükemmel! Hayat kalitenizi değiştirecek bir artış."
    }

    func commuteSummaryString() -> String {
        if weeklyCommuteSavedMinutes > 180 {
            let days = Int(round(annualLostDaysSaved))
            return "Yılda fazladan yaklaşık \(days) gün size kalacak."
        } else if weeklyCommuteSavedMinutes > 60 {
            return "Haftalık yol süresinde belirgin bir tasarruf var."
        } else if weeklyCommuteSavedMinutes > 0 {
            return "Küçük bir yol süresi iyileşmesi var."
        } else {
            return "Yol süresinde anlamlı bir kazanım yok."
        }
    }
}

