import Foundation

// MARK: - API / Karşılaştırma Tablosu Uyumlu Enum'lar
enum CalismaModeli: String, Codable, CaseIterable {
    case ofis = "Ofis"
    case hibrit = "Hibrit"
    case remote = "Remote"
}

// MARK: - JobComparison (embedded for build inclusion)
struct JobComparison {
    let current: YanHakVerisi
    let offer: YanHakVerisi

    var currentMonthlyNet: [Double] { current.aylikNetMaaslar }
    var offerMonthlyNet: [Double] { offer.aylikNetMaaslar }

    var currentYearlyNet: Double { current.yillikNetMaas }
    var offerYearlyNet: Double { offer.yillikNetMaas }

    var currentYearlyNetWithBonus: Double { current.primDahilYillikToplam }
    var offerYearlyNetWithBonus: Double { offer.primDahilYillikToplam }

    func annualBenefitsValue(for v: YanHakVerisi) -> Double {
        var total: Double = 0
        if let t = v.tamamlayiciSaglikTutar { total += max(0, t) }
        if let t = v.ozelSaglikTutar { total += max(0, t) }
        if let t = v.gozDisDestekTutar { total += max(0, t) }
        if v.yemekTipi == .yemekKarti, let daily = v.yemekKartiGunlukTutar {
            let workDaysPerYear = Double(v.officeDaysPerWeek) * 52.0
            total += daily * workDaysPerYear
        }
        if v.yemekTipi == .yemekhane {
            let workDaysPerYear = Double(v.officeDaysPerWeek) * 52.0
            total += 60.0 * workDaysPerYear
        }
        if let aylik = v.yolUcretiAylik { total += aylik * 12.0 }
        if let aylik = v.sirketAraciYakitAylik { total += aylik * 12.0 }
        if v.internetElektrikDestekVar, let tutar = v.internetElektrikToplamTutar { total += tutar }
        if let egitim = v.egitimButcesi { total += egitim }
        if v.telefonVeriliyor || (v.telefonFaturaKarsilaniyor ?? false) { total += 60.0 * 12.0 }
        if v.bankaPromosyonu { total += 300.0 }
        if v.bayramYardimiVar { total += 500.0 }
        return max(0, total)
    }

    var currentAnnualBenefits: Double { annualBenefitsValue(for: current) }
    var offerAnnualBenefits: Double { annualBenefitsValue(for: offer) }

    var currentTotalCompensation: Double { currentYearlyNetWithBonus + currentAnnualBenefits }
    var offerTotalCompensation: Double { offerYearlyNetWithBonus + offerAnnualBenefits }

    func weeklyCommuteMinutes(for v: YanHakVerisi) -> Int {
        let oneWay = v.commuteTimeInMinutes ?? 0
        return (oneWay * 2) * v.officeDaysPerWeek
    }

    var currentWeeklyCommuteMinutes: Int { weeklyCommuteMinutes(for: current) }
    var offerWeeklyCommuteMinutes: Int { weeklyCommuteMinutes(for: offer) }

    func annualLostDays(for v: YanHakVerisi) -> Double {
        let weeklyHours = Double(weeklyCommuteMinutes(for: v)) / 60.0
        return (weeklyHours * 52.0) / 24.0
    }

    var currentAnnualLostDays: Double { annualLostDays(for: current) }
    var offerAnnualLostDays: Double { annualLostDays(for: offer) }

    var percentChangeTotalCompensation: Double {
        let base = max(1.0, currentTotalCompensation)
        return (offerTotalCompensation - currentTotalCompensation) / base * 100.0
    }

    var monthlyDelta: Double { (offerYearlyNetWithBonus/12.0) - (currentYearlyNetWithBonus/12.0) }

    var lifeQualityScore: Int {
        let pct = percentChangeTotalCompensation
        let financialScore = min(max(pct, -50), 50) / 50.0 * 50.0
        let savedMinutes = Double(currentWeeklyCommuteMinutes - offerWeeklyCommuteMinutes)
        let commuteScore = min(max(savedMinutes / (60.0 * 2.0) * 10.0, -20.0), 30.0)
        let benefitRatio = (offerAnnualBenefits - currentAnnualBenefits) / max(1.0, currentAnnualBenefits + 1.0)
        let benefitScore = min(max(benefitRatio * 25.0, -10.0), 20.0)
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

    func raiseAnalysisString() -> String {
        let pct = percentChangeTotalCompensation
        switch pct {
        case ..<5: return "Finansal olarak önemsiz bir değişim."
        case 5..<10: return "Küçük ancak dikkat çekmesi gereken bir artış; pazarlık için bazı yan haklar değerlendirilebilir."
        case 10..<20: return "Makul ve kabul edilebilir bir artış."
        case 20..<30: return "Güçlü bir finansal sıçrama."
        default: return "Mükemmel! Hayat kalitenizi değiştirecek bir artış."
        }
    }

    func careerImpactString() -> String {
        guard let terfi = offer.terfiIleMi, terfi == true else { return "" }
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

    func shortSummary() -> String {
        let pct = Int(round(percentChangeTotalCompensation))
        let money = FinanceFormatter.currencyString(monthlyDelta)
        return "\(raiseAnalysisString()) Net aylık fark: \(money) (%\(pct)) — Yaşam Kalitesi: \(lifeQualityScore)/100"
    }
}

enum UlasimTipi: String, Codable, CaseIterable {
    case sirketAraci = "Şirket Araçı"
    case servis = "Servis İmkanı"
    case yolUcreti = "Yol Ücreti"
    case hicbiri = "Hiçbiri"
}

enum YemekTipi: String, Codable, CaseIterable {
    case yemekhane = "Yemekhane"
    case yemekKarti = "Yemek Kartı"
}

/// Yan hak analizi — Mevcut iş veya Teklif için tüm bilgiler (API ve karşılaştırma tablosu için Codable)
class YanHakVerisi: ObservableObject, Identifiable, Codable {
    let id: UUID
    
    // 1. Ücret
    @Published var brutMaas: Double = 0
    @Published var ucretBrutMu: Bool = true
    @Published var maasPeriyodu: Int = 12
    
    // 1b. Kıdem (sadece mevcut iş)
    @Published var mevcutIsYil: Int?
    
    // 1c. Terfi ile mi gidildi (teklif analizi)
    @Published var terfiIleMi: Bool?
    
    // 2. Çalışma Modeli
    @Published var calismaModeli: CalismaModeli?
    @Published var hibritGunSayisi: Int?  // Sadece hibrit seçilince, 1–5
    
    // 3. İzin
    @Published var yillikIzinGunu: Int?
    
    // 4. Telefon
    @Published var telefonVeriliyor: Bool = false
    @Published var telefonFaturaKarsilaniyor: Bool?
    
    // 5. Prim / Bonus
    @Published var yillikPrimBonusTutar: Double?
    
    // 6. Sigorta (ticklenebilir)
    @Published var tamamlayiciSaglikVar: Bool = false
    @Published var tamamlayiciSaglikAileKapsami: Bool = false
    @Published var tamamlayiciSaglikTutar: Double?
    @Published var ozelSaglikVar: Bool = false
    @Published var ozelSaglikAileKapsami: Bool = false
    @Published var ozelSaglikTutar: Double?
    @Published var gozDisDestegiVar: Bool = false
    @Published var gozDisDestekTutar: Double?
    
    // 7. Yemek
    @Published var yemekTipi: YemekTipi?
    @Published var yemekKartiGunlukTutar: Double?  // Yemek kartı seçilince
    @Published var yemekhaneKalitePuan: Int?  // Yemekhane seçilince 1–5
    
    // 8. Ulaşım
    @Published var ulasimTipi: UlasimTipi?
    @Published var yolUcretiAylik: Double?
    @Published var sirketAraciYakitAylik: Double?
    @Published var yoldaSureSaat: Int?
    @Published var yoldaSureDakika: Int?
    
    // 9. İnternet, Elektrik vb. Destek
    @Published var internetElektrikDestekVar: Bool = false
    @Published var internetElektrikToplamTutar: Double?
    
    // Eski alanlar (geriye uyumluluk)
    @Published var bankaPromosyonu: Bool = false
    @Published var besKatkiYuzde: Double?
    @Published var egitimButcesi: Double?
    @Published var yabanciDilTazminat: Bool = false
    @Published var bayramYardimiVar: Bool = false
    @Published var sporHobiVar: Bool = false
    
    init(id: UUID = UUID()) {
        self.id = id
    }
    
    enum CodingKeys: String, CodingKey {
        case id, brutMaas, ucretBrutMu, maasPeriyodu
        case mevcutIsYil, terfiIleMi
        case calismaModeli, hibritGunSayisi, yillikIzinGunu
        case telefonVeriliyor, telefonFaturaKarsilaniyor, yillikPrimBonusTutar
        case tamamlayiciSaglikVar, tamamlayiciSaglikAileKapsami, tamamlayiciSaglikTutar
        case ozelSaglikVar, ozelSaglikAileKapsami, ozelSaglikTutar
        case gozDisDestegiVar, gozDisDestekTutar
        case yemekTipi, yemekKartiGunlukTutar, yemekhaneKalitePuan
        case ulasimTipi, yolUcretiAylik, sirketAraciYakitAylik
        case yoldaSureSaat, yoldaSureDakika
        case internetElektrikDestekVar, internetElektrikToplamTutar
    }
    
    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        brutMaas = try c.decodeIfPresent(Double.self, forKey: .brutMaas) ?? 0
        ucretBrutMu = try c.decodeIfPresent(Bool.self, forKey: .ucretBrutMu) ?? true
        maasPeriyodu = try c.decodeIfPresent(Int.self, forKey: .maasPeriyodu) ?? 12
        mevcutIsYil = try c.decodeIfPresent(Int.self, forKey: .mevcutIsYil)
        terfiIleMi = try c.decodeIfPresent(Bool.self, forKey: .terfiIleMi)
        calismaModeli = try c.decodeIfPresent(CalismaModeli.self, forKey: .calismaModeli)
        hibritGunSayisi = try c.decodeIfPresent(Int.self, forKey: .hibritGunSayisi)
        yillikIzinGunu = try c.decodeIfPresent(Int.self, forKey: .yillikIzinGunu)
        telefonVeriliyor = try c.decodeIfPresent(Bool.self, forKey: .telefonVeriliyor) ?? false
        telefonFaturaKarsilaniyor = try c.decodeIfPresent(Bool.self, forKey: .telefonFaturaKarsilaniyor)
        yillikPrimBonusTutar = try c.decodeIfPresent(Double.self, forKey: .yillikPrimBonusTutar)
        tamamlayiciSaglikVar = try c.decodeIfPresent(Bool.self, forKey: .tamamlayiciSaglikVar) ?? false
        tamamlayiciSaglikAileKapsami = try c.decodeIfPresent(Bool.self, forKey: .tamamlayiciSaglikAileKapsami) ?? false
        tamamlayiciSaglikTutar = try c.decodeIfPresent(Double.self, forKey: .tamamlayiciSaglikTutar)
        ozelSaglikVar = try c.decodeIfPresent(Bool.self, forKey: .ozelSaglikVar) ?? false
        ozelSaglikAileKapsami = try c.decodeIfPresent(Bool.self, forKey: .ozelSaglikAileKapsami) ?? false
        ozelSaglikTutar = try c.decodeIfPresent(Double.self, forKey: .ozelSaglikTutar)
        gozDisDestegiVar = try c.decodeIfPresent(Bool.self, forKey: .gozDisDestegiVar) ?? false
        gozDisDestekTutar = try c.decodeIfPresent(Double.self, forKey: .gozDisDestekTutar)
        yemekTipi = try c.decodeIfPresent(YemekTipi.self, forKey: .yemekTipi)
        yemekKartiGunlukTutar = try c.decodeIfPresent(Double.self, forKey: .yemekKartiGunlukTutar)
        yemekhaneKalitePuan = try c.decodeIfPresent(Int.self, forKey: .yemekhaneKalitePuan)
        ulasimTipi = try c.decodeIfPresent(UlasimTipi.self, forKey: .ulasimTipi)
        yolUcretiAylik = try c.decodeIfPresent(Double.self, forKey: .yolUcretiAylik)
        sirketAraciYakitAylik = try c.decodeIfPresent(Double.self, forKey: .sirketAraciYakitAylik)
        yoldaSureSaat = try c.decodeIfPresent(Int.self, forKey: .yoldaSureSaat)
        yoldaSureDakika = try c.decodeIfPresent(Int.self, forKey: .yoldaSureDakika)
        internetElektrikDestekVar = try c.decodeIfPresent(Bool.self, forKey: .internetElektrikDestekVar) ?? false
        internetElektrikToplamTutar = try c.decodeIfPresent(Double.self, forKey: .internetElektrikToplamTutar)
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(brutMaas, forKey: .brutMaas)
        try c.encode(ucretBrutMu, forKey: .ucretBrutMu)
        try c.encode(maasPeriyodu, forKey: .maasPeriyodu)
        try c.encodeIfPresent(mevcutIsYil, forKey: .mevcutIsYil)
        try c.encodeIfPresent(terfiIleMi, forKey: .terfiIleMi)
        try c.encodeIfPresent(calismaModeli, forKey: .calismaModeli)
        try c.encodeIfPresent(hibritGunSayisi, forKey: .hibritGunSayisi)
        try c.encodeIfPresent(yillikIzinGunu, forKey: .yillikIzinGunu)
        try c.encode(telefonVeriliyor, forKey: .telefonVeriliyor)
        try c.encodeIfPresent(telefonFaturaKarsilaniyor, forKey: .telefonFaturaKarsilaniyor)
        try c.encodeIfPresent(yillikPrimBonusTutar, forKey: .yillikPrimBonusTutar)
        try c.encode(tamamlayiciSaglikVar, forKey: .tamamlayiciSaglikVar)
        try c.encode(tamamlayiciSaglikAileKapsami, forKey: .tamamlayiciSaglikAileKapsami)
        try c.encodeIfPresent(tamamlayiciSaglikTutar, forKey: .tamamlayiciSaglikTutar)
        try c.encode(ozelSaglikVar, forKey: .ozelSaglikVar)
        try c.encode(ozelSaglikAileKapsami, forKey: .ozelSaglikAileKapsami)
        try c.encodeIfPresent(ozelSaglikTutar, forKey: .ozelSaglikTutar)
        try c.encode(gozDisDestegiVar, forKey: .gozDisDestegiVar)
        try c.encodeIfPresent(gozDisDestekTutar, forKey: .gozDisDestekTutar)
        try c.encodeIfPresent(yemekTipi, forKey: .yemekTipi)
        try c.encodeIfPresent(yemekKartiGunlukTutar, forKey: .yemekKartiGunlukTutar)
        try c.encodeIfPresent(yemekhaneKalitePuan, forKey: .yemekhaneKalitePuan)
        try c.encodeIfPresent(ulasimTipi, forKey: .ulasimTipi)
        try c.encodeIfPresent(yolUcretiAylik, forKey: .yolUcretiAylik)
        try c.encodeIfPresent(sirketAraciYakitAylik, forKey: .sirketAraciYakitAylik)
        try c.encodeIfPresent(yoldaSureSaat, forKey: .yoldaSureSaat)
        try c.encodeIfPresent(yoldaSureDakika, forKey: .yoldaSureDakika)
        try c.encode(internetElektrikDestekVar, forKey: .internetElektrikDestekVar)
        try c.encodeIfPresent(internetElektrikToplamTutar, forKey: .internetElektrikToplamTutar)
    }
    
    /// Brüt seçiliyse ve yılda 12'den fazla maaş varsa: efektif aylık brüt = maasPeriyodu * brutMaas / 12
    /// Örn: 100.000 brüt, 14 maaş → 14*100000/12 = 116.666,67 ₺/ay. Net seçiliyse anlamsız (kullanılmaz).
    var efektifAylikBrut: Double {
        guard brutMaas > 0, ucretBrutMu else { return brutMaas }
        return maasPeriyodu > 12 ? (Double(maasPeriyodu) * brutMaas / 12) : brutMaas
    }
    
    /// Her ayın net maaşı (12 eleman). Brüt ise hesaplanır, net ise aylık ortalamaya bölünür.
    var aylikNetMaaslar: [Double] {
        guard brutMaas > 0 else { return Array(repeating: 0, count: 12) }
        if ucretBrutMu {
            let brutlar = Array(repeating: efektifAylikBrut, count: 12)
            let sonuclar = BrutNetCalculator.hesaplaYillik(brutlar: brutlar)
            return sonuclar.map(\.net)
        }
        let aylikOrt = yillikNetMaas / 12
        return Array(repeating: aylikOrt, count: 12)
    }
    
    /// Prim dahil yıllık toplam (net). Net girildiyse: yillikNetMaas + prim. Brüt girildiyse: maaş+prim brütten nete.
    var primDahilYillikToplam: Double {
        guard brutMaas > 0 else { return 0 }
        let prim = yillikPrimBonusTutar ?? 0
        if ucretBrutMu {
            let brutlar = Array(repeating: efektifAylikBrut, count: 12)
            let primler = Array(repeating: prim / 12, count: 12)
            let sonuclar = BrutNetCalculator.hesaplaYillik(brutlar: brutlar, primler: primler)
            return sonuclar.map(\.net).reduce(0, +)
        }
        return yillikNetMaas + prim
    }
    
    /// Yıllık toplam net maaş. Brüt seçiliyse BrutNetCalculator ile hesaplanır; net seçiliyse maasPeriyodu * tutar.
    var yillikNetMaas: Double {
        guard brutMaas > 0 else { return 0 }
        if ucretBrutMu {
            let brutlar = Array(repeating: efektifAylikBrut, count: 12)
            let sonuclar = BrutNetCalculator.hesaplaYillik(brutlar: brutlar)
            return sonuclar.map(\.net).reduce(0, +)
        }
        return Double(maasPeriyodu) * brutMaas
    }
    
    /// Karşılaştırma tablosu ve AI API için JSON hazır veri
    var karşılastirmaPayload: [String: Any] {
        var d: [String: Any] = [:]
        d["brutMaas"] = brutMaas
        d["ucretBrutMu"] = ucretBrutMu
        d["maasPeriyodu"] = maasPeriyodu
        d["yillikNetMaas"] = yillikNetMaas
        d["calismaModeli"] = calismaModeli?.rawValue
        d["hibritGunSayisi"] = hibritGunSayisi as Any
        d["yillikIzinGunu"] = yillikIzinGunu as Any
        d["telefonVeriliyor"] = telefonVeriliyor
        d["telefonFaturaKarsilaniyor"] = telefonFaturaKarsilaniyor as Any
        d["yillikPrimBonusTutar"] = yillikPrimBonusTutar as Any
        d["mevcutIsYil"] = mevcutIsYil as Any
        d["terfiIleMi"] = terfiIleMi as Any
        d["tamamlayiciSaglikVar"] = tamamlayiciSaglikVar
        d["tamamlayiciSaglikAileKapsami"] = tamamlayiciSaglikAileKapsami
        d["tamamlayiciSaglikTutar"] = tamamlayiciSaglikTutar as Any
        d["ozelSaglikVar"] = ozelSaglikVar
        d["ozelSaglikAileKapsami"] = ozelSaglikAileKapsami
        d["ozelSaglikTutar"] = ozelSaglikTutar as Any
        d["gozDisDestegiVar"] = gozDisDestegiVar
        d["gozDisDestekTutar"] = gozDisDestekTutar as Any
        d["yemekTipi"] = yemekTipi?.rawValue as Any
        d["yemekKartiGunlukTutar"] = yemekKartiGunlukTutar as Any
        d["yemekhaneKalitePuan"] = yemekhaneKalitePuan as Any
        d["ulasimTipi"] = ulasimTipi?.rawValue as Any
        d["yoldaSureSaat"] = yoldaSureSaat as Any
        d["yoldaSureDakika"] = yoldaSureDakika as Any
        d["yolUcretiAylik"] = yolUcretiAylik as Any
        d["sirketAraciYakitAylik"] = sirketAraciYakitAylik as Any
        d["internetElektrikDestekVar"] = internetElektrikDestekVar
        d["internetElektrikToplamTutar"] = internetElektrikToplamTutar as Any
        return d
    }
    
    // MARK: - Commute helpers (backwards compatible)
    /// Tek yön yol süresi (dakika) - mevcut alanlardan türetilir (varsa)
    var commuteTimeInMinutes: Int? {
        if let s = yoldaSureSaat, let m = yoldaSureDakika {
            return s * 60 + m
        }
        return nil
    }

    /// Haftalık ofise gitme gün sayısı (tahmini)
    /// - Hibrit ise `hibritGunSayisi`
    /// - Ofis ise 5
    /// - Remote ise 0
    var officeDaysPerWeek: Int {
        switch calismaModeli {
        case .hibrit:
            return min(5, max(1, hibritGunSayisi ?? 2))
        case .ofis:
            return 5
        default:
            return 0
        }
    }

    // MARK: - Work model & commute comparison helpers
    enum CommuteImpact {
        case major, moderate, minimal, worse
    }

    /// Karşılaştırma: çalışma modeli öncelikleri ve hibrit gün detayı
    static func workModelComparison(mevcut: YanHakVerisi, teklif: YanHakVerisi) -> String {
        func rank(_ d: YanHakVerisi) -> Int {
            switch d.calismaModeli {
            case .remote: return 3
            case .hibrit: return 2
            case .ofis: return 1
            default: return 0
            }
        }
        let mRank = rank(mevcut)
        let tRank = rank(teklif)
        // Eşitlik durumu
        if mRank == tRank {
            if mRank == 2 { // her ikisi de hibrit -> karşılaştır hibrit gün sayısı
                let mDays = mevcut.hibritGunSayisi ?? 3
                let tDays = teklif.hibritGunSayisi ?? 3
                if mDays == tDays {
                    return "Her iki teklif de hibrit ve haftada \(mDays) gün ofise gitmeyi öngörüyor; esneklik bakımından eşit."
                } else if tDays < mDays {
                    return "Yeni teklif haftada \(tDays) gün ofise gidilmesini öngörüyor; mevcut \(mDays) güne kıyasla daha fazla esneklik sunuyor."
                } else {
                    return "Yeni teklif haftada \(tDays) gün ofise gidilmesini öngörüyor; mevcut \(mDays) güne kıyasla daha az esneklik sunuyor."
                }
            }
            // eşitse Remote/Office eşitliği vb.
            return "Her iki iş de aynı çalışma modelini (\(mevcut.calismaModeli?.rawValue ?? "—")) sunuyor."
        }
        // Farklılık: Remote > Hibrit > Ofis
        if tRank > mRank {
            return "Yeni teklif, \(teklif.calismaModeli?.rawValue ?? "—") modeliyle mevcut işinize göre daha fazla esneklik sunuyor."
        } else {
            return "Yeni teklif, \(teklif.calismaModeli?.rawValue ?? "—") modeliyle mevcut işinize göre daha az esneklik sunuyor."
        }
    }

    /// Haftalık yol süresi hesapla ve kategoriye göre yorum döndür
    static func commuteComparison(mevcut: YanHakVerisi, teklif: YanHakVerisi) -> (message: String, impact: CommuteImpact, minutesSaved: Int) {
        let mOneWay = mevcut.commuteTimeInMinutes ?? 0
        let tOneWay = teklif.commuteTimeInMinutes ?? 0
        let mWeekly = (mOneWay * 2) * mevcut.officeDaysPerWeek
        let tWeekly = (tOneWay * 2) * teklif.officeDaysPerWeek
        let diff = mWeekly - tWeekly // pozitif => tasarruf
        let absMinutes = abs(diff)
        if diff > 180 { // ciddi (>180)
            let hours = Int(round(Double(absMinutes)/60.0))
            return ("Muazzam! Yeni düzeninizde haftalık yaklaşık \(hours) saat yoldan tasarruf ederek bu zamanı kendinize ayırabilirsiniz. Bu, yaşam kalitenizde anlamlı bir iyileşme sağlar.", .major, absMinutes)
        } else if diff > 60 {
            return ("Güzel bir iyileşme. Haftalık \(absMinutes) dakikalık yol tasarrufu, ayda yaklaşık bir tam günü yolda geçirmekten kurtulacağınız anlamına geliyor.", .moderate, absMinutes)
        } else if diff >= 0 && diff <= 30 {
            return ("Yol süresinde \(absMinutes) dakikalık küçük bir iyileşme var; günlük rutininizde büyük bir fark yaratmasa da olumlu bir adım.", .minimal, absMinutes)
        } else { // negatif veya artış
            let hours = Int(round(Double(absMinutes)/60.0))
            return ("Dikkat: Yeni teklifte haftalık yaklaşık \(hours) saat daha fazla yolda vakit geçireceksiniz. Bu durumun yaratacağı yorgunluğu göz önünde bulundurmalısınız.", .worse, absMinutes)
        }
    }
    
    /// Derin kopya — kaydetme için
    func kopyala() -> YanHakVerisi? {
        guard let data = try? JSONEncoder().encode(self),
              let kopya = try? JSONDecoder().decode(YanHakVerisi.self, from: data) else { return nil }
        return kopya
    }
}
