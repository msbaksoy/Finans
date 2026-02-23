import Foundation

/// Central comparison & logic engine for Job Offer analysis.
/// - Uses existing `YanHakVerisi` model and `BrutNetCalculator` for brüt→net conversions.
struct JobComparison {
    let current: YanHakVerisi
    let offer: YanHakVerisi

    // MARK: - Basic derived numbers
    /// Monthly net arrays (12 elements) for both sides
    var currentMonthlyNet: [Double] { current.aylikNetMaaslar }
    var offerMonthlyNet: [Double] { offer.aylikNetMaaslar }

    /// Yearly net totals (prim dahil değil)
    var currentYearlyNet: Double { current.yillikNetMaas }
    var offerYearlyNet: Double { offer.yillikNetMaas }

    /// Yearly net including declared bonuses/primes
    var currentYearlyNetWithBonus: Double { current.primDahilYillikToplam }
    var offerYearlyNetWithBonus: Double { offer.primDahilYillikToplam }

    // MARK: - Benefit monetization
    /// Estimate of annual net cash-equivalent value for declared benefits
    func annualBenefitsValue(for v: YanHakVerisi) -> Double {
        var total: Double = 0

        // Sağlık / özel destekler (yıllık tutar alanları varsayılan yıllık)
        if let t = v.tamamlayiciSaglikTutar { total += max(0, t) }
        if let t = v.ozelSaglikTutar { total += max(0, t) }
        if let t = v.gozDisDestekTutar { total += max(0, t) }

        // Yemek: yemek kartı günlük tutarı * ofis günleri per year
        if v.yemekTipi == .yemekKarti, let daily = v.yemekKartiGunlukTutar {
            let workDaysPerYear = Double(v.officeDaysPerWeek) * 52.0
            total += daily * workDaysPerYear
        }
        // Yemekhane: approximate value (if chosen) — conservative estimate
        if v.yemekTipi == .yemekhane {
            // assume equivalent of 60₺/day benefit if quality unspecified
            let workDaysPerYear = Double(v.officeDaysPerWeek) * 52.0
            total += 60.0 * workDaysPerYear
        }

        // Ulaşım: monthly explicit fields
        if let aylik = v.yolUcretiAylik { total += aylik * 12.0 }
        if let aylik = v.sirketAraciYakitAylik { total += aylik * 12.0 }

        // Internet / elektrik yearly
        if v.internetElektrikDestekVar, let tutar = v.internetElektrikToplamTutar {
            total += tutar
        }

        // Eğitim bütçesi (yıllık)
        if let egitim = v.egitimButcesi { total += egitim }

        // Telefon: if provided/fatura covered assume a monthly average
        if v.telefonVeriliyor || (v.telefonFaturaKarsilaniyor ?? false) {
            // conservative 60₺/month value
            total += 60.0 * 12.0
        }

        // Other non-modeled benefits: small uplift if flags set
        if v.bankaPromosyonu { total += 300.0 } // yearly promo estimate
        if v.bayramYardimiVar { total += 500.0 }

        return max(0, total)
    }

    var currentAnnualBenefits: Double { annualBenefitsValue(for: current) }
    var offerAnnualBenefits: Double { annualBenefitsValue(for: offer) }

    // MARK: - Total compensation
    var currentTotalCompensation: Double {
        currentYearlyNetWithBonus + currentAnnualBenefits
    }
    var offerTotalCompensation: Double {
        offerYearlyNetWithBonus + offerAnnualBenefits
    }

    // MARK: - Commute math & life-quality
    /// Weekly commute minutes (both ways * office days)
    func weeklyCommuteMinutes(for v: YanHakVerisi) -> Int {
        let oneWay = v.commuteTimeInMinutes ?? 0
        return (oneWay * 2) * v.officeDaysPerWeek
    }

    var currentWeeklyCommuteMinutes: Int { weeklyCommuteMinutes(for: current) }
    var offerWeeklyCommuteMinutes: Int { weeklyCommuteMinutes(for: offer) }

    /// Annual "lost days" due to commute: (weekly hours * 52) / 24
    func annualLostDays(for v: YanHakVerisi) -> Double {
        let weeklyHours = Double(weeklyCommuteMinutes(for: v)) / 60.0
        return (weeklyHours * 52.0) / 24.0
    }

    var currentAnnualLostDays: Double { annualLostDays(for: current) }
    var offerAnnualLostDays: Double { annualLostDays(for: offer) }

    // MARK: - Percentage/Delta metrics
    /// Percent change in total compensation (offer vs current)
    var percentChangeTotalCompensation: Double {
        let base = max(1.0, currentTotalCompensation)
        return (offerTotalCompensation - currentTotalCompensation) / base * 100.0
    }

    /// Monthly delta (offer - current)
    var monthlyDelta: Double {
        (offerYearlyNetWithBonus/12.0) - (currentYearlyNetWithBonus/12.0)
    }

    // MARK: - Life quality heuristic (0..100)
    /// Heuristic combining financial gain, commute improvement, remote score and benefits ratio.
    /// Designed to be interpretable and stable.
    var lifeQualityScore: Int {
        // Normalize percent financial gain into 0..50
        let pct = percentChangeTotalCompensation
        let financialScore = min(max(pct, -50), 50) / 50.0 * 50.0 // -50..50 -> -50..50 mapped then shift
        // Commute improvement score: saved weekly minutes
        let savedMinutes = Double(currentWeeklyCommuteMinutes - offerWeeklyCommuteMinutes)
        let commuteScore = min(max(savedMinutes / (60.0 * 2.0) * 10.0, -20.0), 30.0) // scaled
        // Benefits uplift
        let benefitRatio = (offerAnnualBenefits - currentAnnualBenefits) / max(1.0, currentAnnualBenefits + 1.0)
        let benefitScore = min(max(benefitRatio * 25.0, -10.0), 20.0)
        // Remote/Hybrid bonus
        let workModelBonus: Double = {
            func rank(_ v: YanHakVerisi) -> Int {
                switch v.calismaModeli {
                case .remote: return 3
                case .hibrit: return 2
                case .ofis: return 1
                default: return 0
                }
            }
            return Double(rank(offer) - rank(current)) * 4.0
        }()

        let raw = 50.0 + financialScore * 0.5 + commuteScore + benefitScore + workModelBonus
        let clamped = min(max(raw, 0.0), 100.0)
        return Int(round(clamped))
    }

    // MARK: - AI insight rules (text generation helpers)
    func raiseAnalysisString() -> String {
        let pct = percentChangeTotalCompensation
        switch pct {
        case ..<5:
            return "Finansal olarak önemsiz bir değişim."
        case 5..<10:
            return "Küçük ancak dikkat çekmesi gereken bir artış; pazarlık için bazı yan haklar değerlendirilebilir."
        case 10..<20:
            return "Makul ve kabul edilebilir bir artış."
        case 20..<30:
            return "Güçlü bir finansal sıçrama."
        default:
            return "Mükemmel! Hayat kalitenizi değiştirecek bir artış."
        }
    }

    func careerImpactString() -> String {
        guard let terfi = offer.terfiIleMi, terfi == true else { return "" }
        // X = baselines: 10% + (financial pct / 2) clamped
        let x = min(40.0, 10.0 + percentChangeTotalCompensation / 2.0)
        return "Ünvan yükselişi, uzun vadeli kariyer değerinizi yaklaşık %\(Int(round(x))) oranında artıracaktır."
    }

    func commuteInsightString() -> String {
        let diff = currentWeeklyCommuteMinutes - offerWeeklyCommuteMinutes
        if diff >= 180 {
            let days = Int(round((Double(diff) / 60.0 * 52.0) / 24.0))
            return "Yılda fazladan \(days) günü kendinize ayırabileceksiniz."
        } else if diff > 60 {
            return "Yeni iş haftalık anlamlı süre kazandırıyor; ayda yaklaşık bir gün kazanabilirsiniz."
        } else if diff > 0 {
            return "Yeni iş küçük ama faydalı zaman tasarrufu sağlıyor."
        } else if diff == 0 {
            return "Yol süresi benzer; zaman tasarrufu beklenmiyor."
        } else {
            return "Yeni işte daha fazla zaman yolculuğunda geçireceksiniz; yaşam kalitesi etkilenebilir."
        }
    }

    // Bundle a short summary used by UI cards
    func shortSummary() -> String {
        let pct = Int(round(percentChangeTotalCompensation))
        let money = FinanceFormatter.currencyString(monthlyDelta)
        return "\(raiseAnalysisString()) Net aylık fark: \(money) (%\(pct)) — Yaşam Kalitesi: \(lifeQualityScore)/100"
    }
}

