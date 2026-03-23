import SwiftUI
import Combine

@MainActor
final class KariyerKiyaslamaViewModel: ObservableObject {
    // MARK: - Akış Yönetimi
    @Published var currentStep: Int = 0

    /// Kullanıcının başta seçtiği analiz tipi (Yol Ayrımı ekranında).
    @Published var isDeepAnalysisSelected: Bool = false

    // Şirket Renkleri
    let currentCompanyColor = Color(hex: "3B82F6") // Electric Blue
    let offerCompanyColor = Color(hex: "8B5CF6")   // Vibrant Purple
    
    // MARK: - Veri Modeli (Geçici State)
    @Published var draft = TeklifKiyaslama()
    
    /// Derin analiz sekmesinden gelen "baştan sona kesintisiz düzenleme" modu için köprü bayrağı.
    @Published var isContinuousEditMode: Bool = false
    
    // UI Kontrolleri için String binding'ler (FormattedNumberField ile uyumlu)
    @Published var mevcutMaasStr: String = "" { didSet { saveDraft() } }
    @Published var teklifMaasStr: String = "" { didSet { saveDraft() } }
    @Published var mevcutPrimStr: String = "" { didSet { saveDraft() } }
    @Published var teklifPrimStr: String = "" { didSet { saveDraft() } }
    @Published var mevcutYemekStr: String = "" { didSet { saveDraft() } }
    @Published var teklifYemekStr: String = "" { didSet { saveDraft() } }

    // Maaş Brüt/Net tercihleri (prim için draft içinde ayrıca var)
    @Published var mevcutMaasBrutMu: Bool = true { didSet { saveDraft() } }
    @Published var teklifMaasBrutMu: Bool = true { didSet { saveDraft() } }
    
    // Yapay Zeka Yorumları (Hızlı ve Derin analizler için ayrı ayrı tutulur)
    @Published var aiHizliYorumu: String? = nil
    @Published var aiDerinYorumu: String? = nil

    // MARK: - Adım içi navigasyon (oturum bazlı, UserDefaults'a yazılmaz)
    @Published var careerQ1Answered: Bool = false
    @Published var workMevcutTamamlandi: Bool = false
    @Published var benefitsProgress: Int = 0  // 0–6; kaç sorunun cevaplandığı

    // MARK: - Init
    
    init() {
        loadDraft()
    }

    /// Kayıtlı kariyer profilini (Mevcut İş) viewModel'e yükler. Yeni teklif eklerken kullanılır.
    func loadBaseProfileAsCurrent() {
        guard let saved = KariyerProfiliManager.shared.baseProfile else { return }

        draft.mevcutSirketAdi = saved.mevcutSirketAdi
        draft.mevcutUnvan = saved.mevcutUnvan
        draft.mevcutUnvanYil = saved.mevcutUnvanYil
        draft.mevcutUnvanRank = saved.mevcutUnvanRank
        draft.mevcutBrutMaas = saved.mevcutBrutMaas
        draft.mevcutMaasSayisi = saved.mevcutMaasSayisi
        draft.mevcutMaasBrutMu = saved.mevcutMaasBrutMu
        draft.mevcutPrimTutar = saved.mevcutPrimTutar
        draft.mevcutPrimBrutMu = saved.mevcutPrimBrutMu
        draft.mevcutGunlukYemekUcreti = saved.mevcutGunlukYemekUcreti
        draft.mevcutAracSegment = saved.mevcutAracSegment
        draft.mevcutBesVarMi = saved.mevcutBesVarMi
        draft.mevcutBesAylikKatki = saved.mevcutBesAylikKatki
        draft.mevcutSigortaTipi = saved.mevcutSigortaTipi
        draft.mevcutSigortaYararlananKisiSayisi = saved.mevcutSigortaYararlananKisiSayisi
        draft.mevcutEvInternetTutar = saved.mevcutEvInternetTutar
        draft.mevcutFaturaDestegiTutar = saved.mevcutFaturaDestegiTutar
        draft.mevcutDilTazminatiTutar = saved.mevcutDilTazminatiTutar
        draft.mevcutCalismaModeli = saved.mevcutCalismaModeli
        draft.mevcutYemekTipi = saved.mevcutYemekTipi
        draft.mevcutYillikIzin = saved.mevcutYillikIzin
        draft.mevcutYolSureDakika = saved.mevcutYolSureDakika
        draft.mevcutUlasimKalitesi = saved.mevcutUlasimKalitesi

        mevcutMaasStr = saved.mevcutBrutMaas > 0 ? String(Int(saved.mevcutBrutMaas)) : ""
        mevcutPrimStr = saved.mevcutPrimTutar > 0 ? String(Int(saved.mevcutPrimTutar)) : ""
        mevcutYemekStr = saved.mevcutGunlukYemekUcreti > 0 ? String(Int(saved.mevcutGunlukYemekUcreti)) : ""
        mevcutMaasBrutMu = saved.mevcutMaasBrutMu
        saveDraft()
    }

    // MARK: - Taslak (Draft) Sistemi
    
    func saveDraft() {
        let d = UserDefaults.standard
        d.set(true,                       forKey: "hasDraftKiyaslama")
        d.set(draft.mevcutSirketAdi,      forKey: "draftMevcutSirket")
        d.set(draft.teklifSirketAdi,      forKey: "draftTeklifSirket")
        d.set(mevcutMaasStr,              forKey: "draftMevcutMaasStr")
        d.set(teklifMaasStr,              forKey: "draftTeklifMaasStr")
        d.set(mevcutPrimStr,              forKey: "draftMevcutPrimStr")
        d.set(teklifPrimStr,              forKey: "draftTeklifPrimStr")
        d.set(mevcutMaasBrutMu,           forKey: "draftMevcutMaasBrutMu")
        d.set(teklifMaasBrutMu,           forKey: "draftTeklifMaasBrutMu")
        d.set(draft.mevcutPrimBrutMu,     forKey: "draftMevcutPrimBrutMu")
        d.set(draft.teklifPrimBrutMu,     forKey: "draftTeklifPrimBrutMu")
        d.set(currentStep,                forKey: "draftKiyaslamaCurrentStep")
        d.set(draft.mevcutUnvan,          forKey: "draftMevcutUnvan")
        d.set(draft.teklifUnvan,         forKey: "draftTeklifUnvan")
        d.set(draft.mevcutUnvanRank,     forKey: "draftMevcutUnvanRank")
        d.set(draft.teklifUnvanRank,     forKey: "draftTeklifUnvanRank")
        d.set(isDeepAnalysisSelected,     forKey: "draftIsDeepAnalysisSelected")
        // Çalışma modeli, ofis günü, yemek, sigorta, yol süresi (uygulama kapanınca kaybolmasın)
        d.set(draft.mevcutCalismaModeli,  forKey: "draftMevcutCalismaModeli")
        d.set(draft.teklifCalismaModeli,  forKey: "draftTeklifCalismaModeli")
        d.set(draft.mevcutOfisGunSayisi,  forKey: "draftMevcutOfisGunSayisi")
        d.set(draft.teklifOfisGunSayisi,  forKey: "draftTeklifOfisGunSayisi")
        d.set(draft.mevcutYemekTipi,      forKey: "draftMevcutYemekTipi")
        d.set(draft.teklifYemekTipi,      forKey: "draftTeklifYemekTipi")
        d.set(draft.mevcutSigortaTipi,    forKey: "draftMevcutSigortaTipi")
        d.set(draft.teklifSigortaTipi,    forKey: "draftTeklifSigortaTipi")
        d.set(draft.mevcutYolSureDakika,  forKey: "draftMevcutYolSureDakika")
        d.set(draft.teklifYolSureDakika,  forKey: "draftTeklifYolSureDakika")
        d.set(draft.mevcutMaasSayisi,     forKey: "draftMevcutMaasSayisi")
        d.set(draft.teklifMaasSayisi,     forKey: "draftTeklifMaasSayisi")
        d.set(draft.mevcutBrutMaas,       forKey: "draftMevcutBrutMaas")
        d.set(draft.teklifBrutMaas,       forKey: "draftTeklifBrutMaas")
        d.set(draft.mevcutPrimTutar,      forKey: "draftMevcutPrimTutar")
        d.set(draft.teklifPrimTutar,      forKey: "draftTeklifPrimTutar")
        d.set(draft.mevcutGunlukYemekUcreti, forKey: "draftMevcutGunlukYemekUcreti")
        d.set(draft.teklifGunlukYemekUcreti, forKey: "draftTeklifGunlukYemekUcreti")
        d.set(draft.mevcutUlasimTipi, forKey: "draftMevcutUlasimTipi")
        d.set(draft.teklifUlasimTipi, forKey: "draftTeklifUlasimTipi")
        d.set(draft.mevcutUlasimKalitesi, forKey: "draftMevcutUlasimKalitesi")
        d.set(draft.teklifUlasimKalitesi, forKey: "draftTeklifUlasimKalitesi")
        d.set(draft.mevcutYemekLezzetYildiz, forKey: "draftMevcutYemekLezzetYildiz")
        d.set(draft.teklifYemekLezzetYildiz, forKey: "draftTeklifYemekLezzetYildiz")
        d.set(draft.mevcutSigortaYararlananKisiSayisi, forKey: "draftMevcutSigortaYararlananKisiSayisi")
        d.set(draft.teklifSigortaYararlananKisiSayisi, forKey: "draftTeklifSigortaYararlananKisiSayisi")
        d.set(draft.mevcutAracSegment, forKey: "draftMevcutAracSegment")
        d.set(draft.teklifAracSegment, forKey: "draftTeklifAracSegment")
        d.set(draft.mevcutBesVarMi, forKey: "draftMevcutBesVarMi")
        d.set(draft.teklifBesVarMi, forKey: "draftTeklifBesVarMi")
        d.set(draft.mevcutBesAylikKatki, forKey: "draftMevcutBesAylikKatki")
        d.set(draft.teklifBesAylikKatki, forKey: "draftTeklifBesAylikKatki")
        d.set(draft.mevcutTopluTasimaDestekVarMi, forKey: "draftMevcutTopluTasimaDestekVarMi")
        d.set(draft.teklifTopluTasimaDestekVarMi, forKey: "draftTeklifTopluTasimaDestekVarMi")
        d.set(draft.mevcutTopluTasimaTutar, forKey: "draftMevcutTopluTasimaTutar")
        d.set(draft.teklifTopluTasimaTutar, forKey: "draftTeklifTopluTasimaTutar")
        d.set(draft.mevcutYakitDestekTutar, forKey: "draftMevcutYakitDestekTutar")
        d.set(draft.teklifYakitDestekTutar, forKey: "draftTeklifYakitDestekTutar")
        d.set(draft.mevcutKendiAracAylikGider, forKey: "draftMevcutKendiAracAylikGider")
        d.set(draft.teklifKendiAracAylikGider, forKey: "draftTeklifKendiAracAylikGider")
        d.set(draft.mevcutKendiAracGiderKimin, forKey: "draftMevcutKendiAracGiderKimin")
        d.set(draft.teklifKendiAracGiderKimin, forKey: "draftTeklifKendiAracGiderKimin")
        d.set(draft.mevcutSirketAraciVarMi, forKey: "draftMevcutSirketAraciVarMi")
        d.set(draft.teklifSirketAraciVarMi, forKey: "draftTeklifSirketAraciVarMi")
        d.set(draft.mevcutYillikIzin, forKey: "draftMevcutYillikIzin")
        d.set(draft.teklifYillikIzin, forKey: "draftTeklifYillikIzin")
    }
    
    func loadDraft() {
        let d = UserDefaults.standard
        guard d.bool(forKey: "hasDraftKiyaslama") else { return }

        draft.mevcutSirketAdi  = d.string(forKey: "draftMevcutSirket")  ?? ""
        draft.teklifSirketAdi  = d.string(forKey: "draftTeklifSirket")  ?? ""
        mevcutMaasStr          = d.string(forKey: "draftMevcutMaasStr") ?? ""
        teklifMaasStr          = d.string(forKey: "draftTeklifMaasStr") ?? ""
        mevcutPrimStr          = d.string(forKey: "draftMevcutPrimStr") ?? ""
        teklifPrimStr          = d.string(forKey: "draftTeklifPrimStr") ?? ""
        mevcutMaasBrutMu       = d.object(forKey: "draftMevcutMaasBrutMu")  as? Bool ?? true
        teklifMaasBrutMu       = d.object(forKey: "draftTeklifMaasBrutMu")  as? Bool ?? true
        draft.mevcutPrimBrutMu = d.object(forKey: "draftMevcutPrimBrutMu") as? Bool ?? true
        draft.teklifPrimBrutMu = d.object(forKey: "draftTeklifPrimBrutMu") as? Bool ?? true
        currentStep            = d.integer(forKey: "draftKiyaslamaCurrentStep")
        draft.mevcutUnvan      = d.string(forKey: "draftMevcutUnvan") ?? ""
        draft.teklifUnvan      = d.string(forKey: "draftTeklifUnvan") ?? ""
        draft.mevcutUnvanRank  = d.object(forKey: "draftMevcutUnvanRank") as? Int ?? 1
        draft.teklifUnvanRank  = d.object(forKey: "draftTeklifUnvanRank") as? Int ?? 1
        isDeepAnalysisSelected = d.bool(forKey: "draftIsDeepAnalysisSelected")
        draft.mevcutCalismaModeli  = d.string(forKey: "draftMevcutCalismaModeli") ?? ""
        draft.teklifCalismaModeli  = d.string(forKey: "draftTeklifCalismaModeli") ?? ""
        draft.mevcutOfisGunSayisi  = d.object(forKey: "draftMevcutOfisGunSayisi") as? Int ?? 0
        draft.teklifOfisGunSayisi  = d.object(forKey: "draftTeklifOfisGunSayisi") as? Int ?? 0
        draft.mevcutYemekTipi      = d.string(forKey: "draftMevcutYemekTipi") ?? "Yok"
        draft.teklifYemekTipi      = d.string(forKey: "draftTeklifYemekTipi") ?? "Yok"
        draft.mevcutSigortaTipi    = d.string(forKey: "draftMevcutSigortaTipi") ?? "Yok"
        draft.teklifSigortaTipi    = d.string(forKey: "draftTeklifSigortaTipi") ?? "Yok"
        draft.mevcutYolSureDakika  = d.object(forKey: "draftMevcutYolSureDakika") as? Int ?? 0
        draft.teklifYolSureDakika  = d.object(forKey: "draftTeklifYolSureDakika") as? Int ?? 0
        draft.mevcutMaasSayisi     = d.object(forKey: "draftMevcutMaasSayisi") as? Int ?? 12
        draft.teklifMaasSayisi     = d.object(forKey: "draftTeklifMaasSayisi") as? Int ?? 12
        draft.mevcutBrutMaas       = d.object(forKey: "draftMevcutBrutMaas") as? Double ?? 0
        draft.teklifBrutMaas       = d.object(forKey: "draftTeklifBrutMaas") as? Double ?? 0
        draft.mevcutPrimTutar      = d.object(forKey: "draftMevcutPrimTutar") as? Double ?? 0
        draft.teklifPrimTutar      = d.object(forKey: "draftTeklifPrimTutar") as? Double ?? 0
        draft.mevcutGunlukYemekUcreti = d.object(forKey: "draftMevcutGunlukYemekUcreti") as? Double ?? 0
        draft.teklifGunlukYemekUcreti = d.object(forKey: "draftTeklifGunlukYemekUcreti") as? Double ?? 0
        draft.mevcutUlasimTipi = d.string(forKey: "draftMevcutUlasimTipi") ?? ""
        draft.teklifUlasimTipi = d.string(forKey: "draftTeklifUlasimTipi") ?? ""
        draft.mevcutUlasimKalitesi = d.string(forKey: "draftMevcutUlasimKalitesi") ?? ""
        draft.teklifUlasimKalitesi = d.string(forKey: "draftTeklifUlasimKalitesi") ?? ""
        draft.mevcutYemekLezzetYildiz = d.object(forKey: "draftMevcutYemekLezzetYildiz") as? Int ?? 0
        draft.teklifYemekLezzetYildiz = d.object(forKey: "draftTeklifYemekLezzetYildiz") as? Int ?? 0
        draft.mevcutSigortaYararlananKisiSayisi = d.object(forKey: "draftMevcutSigortaYararlananKisiSayisi") as? Int ?? 1
        draft.teklifSigortaYararlananKisiSayisi = d.object(forKey: "draftTeklifSigortaYararlananKisiSayisi") as? Int ?? 1
        draft.mevcutAracSegment = d.string(forKey: "draftMevcutAracSegment") ?? ""
        draft.teklifAracSegment = d.string(forKey: "draftTeklifAracSegment") ?? ""
        draft.mevcutBesVarMi = d.bool(forKey: "draftMevcutBesVarMi")
        draft.teklifBesVarMi = d.bool(forKey: "draftTeklifBesVarMi")
        draft.mevcutBesAylikKatki = d.string(forKey: "draftMevcutBesAylikKatki") ?? ""
        draft.teklifBesAylikKatki = d.string(forKey: "draftTeklifBesAylikKatki") ?? ""
        draft.mevcutTopluTasimaDestekVarMi = d.bool(forKey: "draftMevcutTopluTasimaDestekVarMi")
        draft.teklifTopluTasimaDestekVarMi = d.bool(forKey: "draftTeklifTopluTasimaDestekVarMi")
        draft.mevcutTopluTasimaTutar = d.string(forKey: "draftMevcutTopluTasimaTutar") ?? ""
        draft.teklifTopluTasimaTutar = d.string(forKey: "draftTeklifTopluTasimaTutar") ?? ""
        draft.mevcutYakitDestekTutar = d.string(forKey: "draftMevcutYakitDestekTutar") ?? ""
        draft.teklifYakitDestekTutar = d.string(forKey: "draftTeklifYakitDestekTutar") ?? ""
        draft.mevcutKendiAracAylikGider = d.string(forKey: "draftMevcutKendiAracAylikGider") ?? ""
        draft.teklifKendiAracAylikGider = d.string(forKey: "draftTeklifKendiAracAylikGider") ?? ""
        draft.mevcutKendiAracGiderKimin = d.string(forKey: "draftMevcutKendiAracGiderKimin") ?? ""
        draft.teklifKendiAracGiderKimin = d.string(forKey: "draftTeklifKendiAracGiderKimin") ?? ""
        draft.mevcutSirketAraciVarMi = d.bool(forKey: "draftMevcutSirketAraciVarMi")
        draft.teklifSirketAraciVarMi = d.bool(forKey: "draftTeklifSirketAraciVarMi")
        draft.mevcutYillikIzin = d.object(forKey: "draftMevcutYillikIzin") as? Int ?? 14
        draft.teklifYillikIzin = d.object(forKey: "draftTeklifYillikIzin") as? Int ?? 14
    }
    
    func clearDraft() {
        draft = TeklifKiyaslama()
        mevcutMaasStr      = ""
        teklifMaasStr      = ""
        mevcutPrimStr      = ""
        teklifPrimStr      = ""
        mevcutYemekStr     = ""
        teklifYemekStr     = ""
        mevcutMaasBrutMu   = true
        teklifMaasBrutMu   = true
        currentStep        = 0
        careerQ1Answered   = false
        workMevcutTamamlandi = false
        benefitsProgress   = 0
        aiHizliYorumu      = nil
        aiDerinYorumu      = nil
        
        ["hasDraftKiyaslama","draftMevcutSirket","draftTeklifSirket",
         "draftMevcutMaasStr","draftTeklifMaasStr","draftMevcutPrimStr","draftTeklifPrimStr",
         "draftMevcutMaasBrutMu","draftTeklifMaasBrutMu",
         "draftMevcutPrimBrutMu","draftTeklifPrimBrutMu",
         "draftKiyaslamaCurrentStep","draftMevcutUnvan","draftTeklifUnvan","draftMevcutUnvanRank","draftTeklifUnvanRank",
         "draftIsDeepAnalysisSelected",
         "draftMevcutCalismaModeli","draftTeklifCalismaModeli","draftMevcutOfisGunSayisi","draftTeklifOfisGunSayisi",
         "draftMevcutYemekTipi","draftTeklifYemekTipi","draftMevcutSigortaTipi","draftTeklifSigortaTipi",
         "draftMevcutYolSureDakika","draftTeklifYolSureDakika","draftMevcutMaasSayisi","draftTeklifMaasSayisi",
         "draftMevcutBrutMaas","draftTeklifBrutMaas","draftMevcutPrimTutar","draftTeklifPrimTutar",
         "draftMevcutGunlukYemekUcreti","draftTeklifGunlukYemekUcreti",
         "draftMevcutUlasimTipi","draftTeklifUlasimTipi","draftMevcutUlasimKalitesi","draftTeklifUlasimKalitesi",
         "draftMevcutYemekLezzetYildiz","draftTeklifYemekLezzetYildiz","draftMevcutSigortaYararlananKisiSayisi","draftTeklifSigortaYararlananKisiSayisi",
         "draftMevcutAracSegment","draftTeklifAracSegment","draftMevcutBesVarMi","draftTeklifBesVarMi","draftMevcutBesAylikKatki","draftTeklifBesAylikKatki",
         "draftMevcutTopluTasimaDestekVarMi","draftTeklifTopluTasimaDestekVarMi","draftMevcutTopluTasimaTutar","draftTeklifTopluTasimaTutar",
         "draftMevcutYakitDestekTutar","draftTeklifYakitDestekTutar","draftMevcutKendiAracAylikGider","draftTeklifKendiAracAylikGider",
         "draftMevcutKendiAracGiderKimin","draftTeklifKendiAracGiderKimin","draftMevcutSirketAraciVarMi","draftTeklifSirketAraciVarMi",
         "draftMevcutYillikIzin","draftTeklifYillikIzin"].forEach {
            UserDefaults.standard.removeObject(forKey: $0)
        }
    }
    
    // MARK: - Fonksiyonlar
    
    /// Bir seçim yapıldığında (Enum/Boolean) bir sonraki soruya yumuşak geçiş yapar
    func advance() { }
    
    /// Unvan kademesi (rank) seçimi: 1–5 (Giriş, Orta, Kıdemli, Yönetim, C-Level)
    func setUnvanRank(isCurrent: Bool, rank: Int) {
        if isCurrent {
            draft.mevcutUnvanRank = max(1, min(5, rank))
        } else {
            draft.teklifUnvanRank = max(1, min(5, rank))
        }
        HapticHelper.triggerImpact(.light)
        saveDraft()
    }
    
    /// Maaş Sayısı Kontrolü (+/-)
    func updateMaasSayisi(isCurrent: Bool, delta: Int) {
        if isCurrent {
            let newValue = draft.mevcutMaasSayisi + delta
            draft.mevcutMaasSayisi = max(1, min(24, newValue))
        } else {
            let newValue = draft.teklifMaasSayisi + delta
            draft.teklifMaasSayisi = max(1, min(24, newValue))
        }
        HapticHelper.triggerImpact(.soft)
    }
    
    // MARK: - Validasyonlar
    var isCareerStepValid: Bool {
        !draft.mevcutSirketAdi.isEmpty && !draft.teklifSirketAdi.isEmpty
    }
    
    var isFinancialStepValid: Bool {
        !mevcutMaasStr.isEmpty && !teklifMaasStr.isEmpty
    }
    
    var isWorkModelStepValid: Bool {
        // En az mevcut çalışma modeli seçilmiş olsun
        !draft.mevcutCalismaModeli.isEmpty
    }
    
    var isBenefitsStepValid: Bool {
        true // Şimdilik serbest; ileride yan hak soruları geldiğinde sıkılaştırılabilir.
    }
    
    // Hesaplama motoruna ham verileri gönderir
    func syncStringsToModel() {
        draft.mevcutBrutMaas          = parseFormattedNumber(mevcutMaasStr)  ?? 0
        draft.teklifBrutMaas          = parseFormattedNumber(teklifMaasStr)  ?? 0
        draft.mevcutMaasBrutMu        = mevcutMaasBrutMu
        draft.teklifMaasBrutMu        = teklifMaasBrutMu
        draft.mevcutPrimTutar         = parseFormattedNumber(mevcutPrimStr)  ?? 0
        draft.teklifPrimTutar         = parseFormattedNumber(teklifPrimStr)  ?? 0
        draft.mevcutGunlukYemekUcreti = parseFormattedNumber(mevcutYemekStr) ?? 0
        draft.teklifGunlukYemekUcreti = parseFormattedNumber(teklifYemekStr) ?? 0
    }

    // MARK: - Hesaplama Motoru (Brüt -> Net Dönüşümleri)
    
    /// Belirtilen şirketin finansal verilerini alır, vergi hesabı yaparak Yıllık Toplam Net ve Aylık Ortalamasını döner.
    /// includePrim=false olduğunda yalnızca sabit maaş dikkate alınır.
    func calculateNet(isCurrent: Bool, includePrim: Bool = true) -> (yillikNet: Double, aylikOrtalama: Double) {
        let maas: Double = parseFormattedNumber(isCurrent ? mevcutMaasStr : teklifMaasStr) ?? 0
        let rawPrim: Double = parseFormattedNumber(isCurrent ? mevcutPrimStr : teklifPrimStr) ?? 0
        let prim: Double = includePrim ? rawPrim : 0
        
        let maasSayisi = isCurrent ? draft.mevcutMaasSayisi : draft.teklifMaasSayisi
        let isMaasBrut = isCurrent ? mevcutMaasBrutMu : teklifMaasBrutMu
        let isPrimBrut = isCurrent ? draft.mevcutPrimBrutMu : draft.teklifPrimBrutMu
        
        var yillikToplamNet = 0.0
        
        // 1) Maaşı 12 aya yay — A seçeneği
        let yillikToplamMaasBrut = isMaasBrut ? (maas * Double(maasSayisi)) : 0
        let aylikOrtalamaBrut = yillikToplamMaasBrut / 12.0
        let brutArray = Array(repeating: aylikOrtalamaBrut, count: 12)
        
        // 2) Prim dağılımı (brüt ise Ocak'a yükle)
        var primBrutArray = Array(repeating: 0.0, count: 12)
        if isPrimBrut && prim > 0 {
            primBrutArray[0] = prim
        }
        
        // 3) Brüt -> Net hesaplama
        let totalBrutToProcess = yillikToplamMaasBrut + (isPrimBrut ? prim : 0)
        
        if totalBrutToProcess > 0 {
            let detaylar = BrutNetCalculator.hesaplaYillikDetayli(brutlar: brutArray, primler: primBrutArray)
            yillikToplamNet += detaylar.reduce(0) { $0 + $1.toplamNetEleGecen }
        }
        
        // 4) Doğrudan net girilen kısımlar
        if !isMaasBrut {
            yillikToplamNet += (maas * Double(maasSayisi))
        }
        if !isPrimBrut && prim > 0 {
            yillikToplamNet += prim
        }
        
        return (yillikToplamNet, yillikToplamNet / 12.0)
    }

    /// Her ay için net maaş (prim hariç) — brüt girildiyse Bordro motoru ile aylar arası farklı net; net girildiyse 12 ay aynı.
    /// Çizgi grafikte “her ay yatacak net” dalgalanmasını göstermek için kullanılır.
    func aylikNetMaasDizisi(isCurrent: Bool) -> [Double] {
        let maas: Double = parseFormattedNumber(isCurrent ? mevcutMaasStr : teklifMaasStr) ?? 0
        let isMaasBrut = isCurrent ? mevcutMaasBrutMu : teklifMaasBrutMu
        guard maas > 0 else { return Array(repeating: 0.0, count: 12) }
        if isMaasBrut {
            let brutArray = Array(repeating: maas, count: 12)
            let primler = Array(repeating: 0.0, count: 12)
            let detaylar = BrutNetCalculator.hesaplaYillikDetayli(brutlar: brutArray, primler: primler)
            return detaylar.map { $0.toplamNetEleGecen }
        } else {
            return Array(repeating: maas, count: 12)
        }
    }

    // MARK: - DEEP DIVE (GİZLİ SERVET VE TAZMİNAT) HESAPLAMALARI
    
    /// Şirket aracı, BES gibi ekstra yan hakların "yıllık net nakit karşılığını" hesaplar.
    func calculateHiddenWealth(isCurrent: Bool) -> Double {
        var hiddenWealth = 0.0
        
        // 1. Şirket aracı kira bedeli (yıllık)
        let segment = isCurrent ? draft.mevcutAracSegment : draft.teklifAracSegment
        if !segment.isEmpty && segment != "Yok" {
            let aylikKira = CarPriceService.shared.monthlyPrice(for: segment)
            hiddenWealth += aylikKira * 12.0
        }
        
        // 2. İşveren BES katkısı (yaklaşık, net maaşın %3'ü varsayımıyla)
        let hasBes = isCurrent ? draft.mevcutBesVarMi : draft.teklifBesVarMi
        if hasBes {
            // Öncelik: Kullanıcının girdiği "aylık toplam BES işveren katkısı" (varsa)
            let besAylikStr = isCurrent ? draft.mevcutBesAylikKatki : draft.teklifBesAylikKatki
            if let besAylik = parseFormattedNumber(besAylikStr), besAylik > 0 {
                hiddenWealth += besAylik * 12.0
            } else {
                // Geriye dönük ve tahmini kullanım için: maaşın %3'ü varsayımı
                let yalinAylik = calculateNet(isCurrent: isCurrent, includePrim: false).aylikOrtalama
                hiddenWealth += yalinAylik * 0.03 * 12.0
            }
        }

        // 3. Ulaşım / Yakıt ve Toplu Taşıma destekleri (aylık TL x 12)
        let yakitDestekTutarStr = isCurrent ? draft.mevcutYakitDestekTutar : draft.teklifYakitDestekTutar
        if let yakitAylik = parseFormattedNumber(yakitDestekTutarStr), yakitAylik > 0 {
            hiddenWealth += yakitAylik * 12.0
        }
        let topluTutarStr = isCurrent ? draft.mevcutTopluTasimaTutar : draft.teklifTopluTasimaTutar
        if let topluAylik = parseFormattedNumber(topluTutarStr), topluAylik > 0 {
            hiddenWealth += topluAylik * 12.0
        }

        // 3b. Kendi aracıyla ulaşıyorsa ve aylık toplam gider biliniyorsa:
        // "Şirket" ödüyorsa gizli servete ekle, "Ben" ödüyorsam paketten düş.
        let ulasimKalitesi = isCurrent ? draft.mevcutUlasimKalitesi : draft.teklifUlasimKalitesi
        if ulasimKalitesi == "Kendi Aracım" {
            let kendiGiderStr = isCurrent ? draft.mevcutKendiAracAylikGider : draft.teklifKendiAracAylikGider
            let kimin = isCurrent ? draft.mevcutKendiAracGiderKimin : draft.teklifKendiAracGiderKimin
            if let kendiGiderAylik = parseFormattedNumber(kendiGiderStr), kendiGiderAylik > 0 {
                let yillik = kendiGiderAylik * 12.0
                if kimin == "Şirket" {
                    hiddenWealth += yillik
                } else if kimin == "Ben" {
                    hiddenWealth -= yillik
                }
            }
        }

        // 4. Ev interneti, fatura desteği, dil tazminatı (aylık TL x 12)
        let evNetStr = isCurrent ? draft.mevcutEvInternetTutar : draft.teklifEvInternetTutar
        if let evNet = parseFormattedNumber(evNetStr), evNet > 0 {
            hiddenWealth += evNet * 12.0
        }
        let faturaStr = isCurrent ? draft.mevcutFaturaDestegiTutar : draft.teklifFaturaDestegiTutar
        if let fatura = parseFormattedNumber(faturaStr), fatura > 0 {
            hiddenWealth += fatura * 12.0
        }
        let dilStr = isCurrent ? draft.mevcutDilTazminatiTutar : draft.teklifDilTazminatiTutar
        if let dil = parseFormattedNumber(dilStr), dil > 0 {
            hiddenWealth += dil * 12.0
        }
        
        // 5. Harcırah: günlük net tutarı, aylık ≈ 20 iş günü varsayılarak yıllığa çevir
        let harcirahStr = isCurrent ? draft.mevcutHarcirahTutar : draft.teklifHarcirahTutar
        if let dailyHarcirah = parseFormattedNumber(harcirahStr), dailyHarcirah > 0 {
            let aylikHarcirah = dailyHarcirah * 20.0
            hiddenWealth += aylikHarcirah * 12.0
        }
        
        // 6. Yemek değeri: Sadece ikisinde de günlük yemek bedeli (Yemek Kartı) girilmişse pakete dahil et.
        // Biri yemekhane biri yemek kartı ise hesaplama yapma (birbirini karşılıyor kabul et).
        let mevcutYemek = draft.mevcutYemekTipi
        let teklifYemek = draft.teklifYemekTipi
        let biriYemekhaneBiriKart = (mevcutYemek == "Yemekhane" && teklifYemek == "Yemek Kartı") || (mevcutYemek == "Yemek Kartı" && teklifYemek == "Yemekhane")
        if !biriYemekhaneBiriKart && mevcutYemek == "Yemek Kartı" && teklifYemek == "Yemek Kartı" {
            let mevcutGunluk = draft.mevcutGunlukYemekUcreti
            let teklifGunluk = draft.teklifGunlukYemekUcreti
            if mevcutGunluk > 0 && teklifGunluk > 0 {
                let gunlukYemek = isCurrent ? mevcutGunluk : teklifGunluk
                let aylikYemek = gunlukYemek * 22.0
                hiddenWealth += aylikYemek * 12.0
            }
        }
        
        // 7. Sağlık sigortası değeri: Gist yıllık × ailemi kapsıyor ise yararlanan kişi sayısı
        let sigortaTipi = isCurrent ? draft.mevcutSigortaTipi : draft.teklifSigortaTipi
        let kisiSayisi = isCurrent ? draft.mevcutSigortaYararlananKisiSayisi : draft.teklifSigortaYararlananKisiSayisi
        let sigortaYillik = HealthInsurancePriceService.shared.yearlyPrice(for: sigortaTipi)
        if sigortaYillik > 0 {
            hiddenWealth += sigortaYillik * Double(max(1, kisiSayisi))
        }
        
        return hiddenWealth
    }
    
    /// Tüm maaş, prim ve gizli servetlerin toplamını veren "Gerçek Yıllık Paket".
    func calculateTrueTotalPackage(isCurrent: Bool) -> Double {
        let standartToplam = calculateNet(isCurrent: isCurrent, includePrim: true).yillikNet
        let gizliServet = calculateHiddenWealth(isCurrent: isCurrent)
        return standartToplam + gizliServet
    }

    // MARK: - Üç Grafik için Hesaplamalar (Analiz sayfası)

    /// Grafik 1: Yıllık net maaş (prim dahil değil).
    func graph1YillikNetMaas(isCurrent: Bool) -> Double {
        return calculateNet(isCurrent: isCurrent, includePrim: false).yillikNet
    }

    /// Grafik 2: Yıllık net maaş + net prim toplamı.
    func graph2NetMaasVePrim(isCurrent: Bool) -> Double {
        return calculateNet(isCurrent: isCurrent, includePrim: true).yillikNet
    }

    /// Grafik 3: Toplam paket — net maaş + net prim + ulaşım + yemek + sigorta (× kişi) + BES.
    /// Formül: 1) Net maaş 2) Net prim 3) Ulaşım (şirket aracı kira×12, yakıt×12, toplu taşıma ±×12)
    /// 4) Yemekhane (yıldıza göre günlük×21×12) veya yemek kartı (günlük×21×12) 5) ÖSS/TSS×kişi 6) BES×12
    func graph3ToplamPaket(isCurrent: Bool) -> Double {
        let m = draft
        var toplam = 0.0

        // 1. Yıllık net maaş
        toplam += graph1YillikNetMaas(isCurrent: isCurrent)

        // 2. Yıllık net prim
        let maasPrim = graph2NetMaasVePrim(isCurrent: isCurrent)
        let yalinMaas = graph1YillikNetMaas(isCurrent: isCurrent)
        toplam += maasPrim - yalinMaas

        // 3. Ulaşım
        // a) Şirket aracı: segment dolu ise aylık kira × 12 (varsayılan yok)
        let segment = isCurrent ? m.mevcutAracSegment : m.teklifAracSegment
        if !segment.isEmpty && segment != "Yok" {
            toplam += CarPriceService.shared.monthlyPrice(for: segment) * 12.0
        }
        // b) Aylık yakıt desteği (şirket veriyorsa)
        let yakitStr = isCurrent ? m.mevcutYakitDestekTutar : m.teklifYakitDestekTutar
        if let yakitAylik = parseFormattedNumber(yakitStr), yakitAylik > 0 {
            toplam += yakitAylik * 12.0
        }
        // c) Toplu ulaşım: şirket karşılıyorsa +, cebimden ise -
        let topluTutarStr = isCurrent ? m.mevcutTopluTasimaTutar : m.teklifTopluTasimaTutar
        let destekVar = isCurrent ? m.mevcutTopluTasimaDestekVarMi : m.teklifTopluTasimaDestekVarMi
        if let topluAylik = parseFormattedNumber(topluTutarStr), topluAylik > 0 {
            let yillik = topluAylik * 12.0
            toplam += destekVar ? yillik : -yillik
        }

        // 4. Yemekhane (yıldıza göre günlük değer × 21 × 12) veya Yemek kartı (günlük × 21 × 12)
        let yemekTipi = isCurrent ? m.mevcutYemekTipi : m.teklifYemekTipi
        let yildiz = isCurrent ? m.mevcutYemekLezzetYildiz : m.teklifYemekLezzetYildiz
        if yemekTipi == "Yemekhane" && yildiz >= 1 && yildiz <= 5 {
            let gunlukDeger: Double = [0, 300, 350, 400, 480, 550][yildiz]
            toplam += gunlukDeger * 21.0 * 12.0
        } else if yemekTipi == "Yemek Kartı" {
            let gunluk = isCurrent ? m.mevcutGunlukYemekUcreti : m.teklifGunlukYemekUcreti
            if gunluk > 0 {
                toplam += gunluk * 21.0 * 12.0
            }
        }

        // 5. ÖSS / TSS: Gist yıllık × yararlanan kişi sayısı
        let sigortaTipi = isCurrent ? m.mevcutSigortaTipi : m.teklifSigortaTipi
        let kisiSayisi = isCurrent ? m.mevcutSigortaYararlananKisiSayisi : m.teklifSigortaYararlananKisiSayisi
        let sigortaYillik = HealthInsurancePriceService.shared.yearlyPrice(for: sigortaTipi)
        if sigortaYillik > 0 {
            toplam += sigortaYillik * Double(max(1, kisiSayisi))
        }

        // 6. BES: aylık katkı × 12
        let besStr = isCurrent ? m.mevcutBesAylikKatki : m.teklifBesAylikKatki
        if let besAylik = parseFormattedNumber(besStr), besAylik > 0 {
            toplam += besAylik * 12.0
        }

        return toplam
    }
    
    /// İçeride bırakılan tahmini kıdem tazminatı (basitleştirilmiş formül).
    func calculateKidemTazminatiRiski() -> Double {
        let yil = draft.mevcutUnvanYil
        guard yil >= 1 else { return 0 }
        
        // Maaş
        let mevcutMaas: Double = parseFormattedNumber(mevcutMaasStr) ?? 0
        let isBrut = mevcutMaasBrutMu
        
        // Kabataslak brüt hesaplama (net girildiyse)
        let tahminiBrut = isBrut ? mevcutMaas : (mevcutMaas / 0.75)
        
        // 2024-2025 kıdem tavanı (TL) — istersek AppConfig'ten de çekebiliriz.
        let kidemTavan = 41_828.0
        let gecerliMatrah = min(tahminiBrut, kidemTavan)
        
        return gecerliMatrah * Double(yil)
    }

    // MARK: - Gizli Servet Kırılımı (Premium Derin Analiz için)

    /// Arayüzdeki 'Hesap Fişi' listesi için gizli servet kalemlerini yan yana kıyaslamalı döndürür.
    func getGizliServetKirilimi() -> [GizliServetKalemi] {
        var liste: [GizliServetKalemi] = []
        let m = draft

        // 1. Araç Kiralama (aylık * 12)
        let mArac = CarPriceService.shared.monthlyPrice(for: m.mevcutAracSegment) * 12
        let tArac = CarPriceService.shared.monthlyPrice(for: m.teklifAracSegment) * 12
        if mArac > 0 || tArac > 0 {
            liste.append(GizliServetKalemi(ikon: "car.fill", baslik: "Şirket Aracı (Kira Karşılığı)", mevcutDeger: mArac, teklifDeger: tArac))
        }

        // 2. Sağlık Sigortası (Gist yıllık × ailemi kapsıyor ise yararlanan kişi sayısı)
        let mSigortaBase = HealthInsurancePriceService.shared.yearlyPrice(for: m.mevcutSigortaTipi)
        let tSigortaBase = HealthInsurancePriceService.shared.yearlyPrice(for: m.teklifSigortaTipi)
        let mSigorta = mSigortaBase * Double(max(1, m.mevcutSigortaYararlananKisiSayisi))
        let tSigorta = tSigortaBase * Double(max(1, m.teklifSigortaYararlananKisiSayisi))
        if mSigorta > 0 || tSigorta > 0 {
            liste.append(GizliServetKalemi(ikon: "cross.case.fill", baslik: "Sağlık Sigortası", mevcutDeger: mSigorta, teklifDeger: tSigorta))
        }

        // 3. Yemek
        let mYemek = m.mevcutYemekTipi == "Yemekhane" ? (300.0 * 22 * 12) : (m.mevcutGunlukYemekUcreti * 22 * 12)
        let tYemek = m.teklifYemekTipi == "Yemekhane" ? (300.0 * 22 * 12) : (m.teklifGunlukYemekUcreti * 22 * 12)
        if mYemek > 0 || tYemek > 0 {
            liste.append(GizliServetKalemi(ikon: "fork.knife", baslik: "Yemek İmkânı", mevcutDeger: mYemek, teklifDeger: tYemek))
        }

        // 4. BES
        let mBes = (parseFormattedNumber(m.mevcutBesAylikKatki) ?? 0) * 12
        let tBes = (parseFormattedNumber(m.teklifBesAylikKatki) ?? 0) * 12
        if mBes > 0 || tBes > 0 {
            liste.append(GizliServetKalemi(ikon: "umbrella.fill", baslik: "BES Şirket Katkısı", mevcutDeger: mBes, teklifDeger: tBes))
        }

        // 5. Ulaşım ve Yakıt (Kendi aracı eksi durumu dahil)
        var mUlasim = (parseFormattedNumber(m.mevcutTopluTasimaTutar) ?? 0) * 12
        if m.mevcutUlasimKalitesi == "Kendi Aracım" {
            let gider = (parseFormattedNumber(m.mevcutKendiAracAylikGider) ?? 0) * 12
            mUlasim += (m.mevcutKendiAracGiderKimin == "Şirket" ? gider : -gider)
        } else {
            mUlasim += (parseFormattedNumber(m.mevcutYakitDestekTutar) ?? 0) * 12
        }
        var tUlasim = (parseFormattedNumber(m.teklifTopluTasimaTutar) ?? 0) * 12
        if m.teklifUlasimKalitesi == "Kendi Aracım" {
            let gider = (parseFormattedNumber(m.teklifKendiAracAylikGider) ?? 0) * 12
            tUlasim += (m.teklifKendiAracGiderKimin == "Şirket" ? gider : -gider)
        } else {
            tUlasim += (parseFormattedNumber(m.teklifYakitDestekTutar) ?? 0) * 12
        }
        if mUlasim != 0 || tUlasim != 0 {
            liste.append(GizliServetKalemi(ikon: "bus.fill", baslik: "Ulaşım / Yakıt / Akbil", mevcutDeger: mUlasim, teklifDeger: tUlasim))
        }

        // 6. Ev Bütçesi (İnternet + Fatura)
        let mEv = ((parseFormattedNumber(m.mevcutEvInternetTutar) ?? 0) + (parseFormattedNumber(m.mevcutFaturaDestegiTutar) ?? 0)) * 12
        let tEv = ((parseFormattedNumber(m.teklifEvInternetTutar) ?? 0) + (parseFormattedNumber(m.teklifFaturaDestegiTutar) ?? 0)) * 12
        if mEv > 0 || tEv > 0 {
            liste.append(GizliServetKalemi(ikon: "wifi.router.fill", baslik: "İnternet ve Fatura", mevcutDeger: mEv, teklifDeger: tEv))
        }

        // 7. Yabancı Dil
        let mDil = (parseFormattedNumber(m.mevcutDilTazminatiTutar) ?? 0) * 12
        let tDil = (parseFormattedNumber(m.teklifDilTazminatiTutar) ?? 0) * 12
        if mDil > 0 || tDil > 0 {
            liste.append(GizliServetKalemi(ikon: "character.book.closed.fill", baslik: "Yabancı Dil Tazminatı", mevcutDeger: mDil, teklifDeger: tDil))
        }

        // 8. Harcırah (günlük * 20 iş günü * 12 ay)
        let mHarcirah = (parseFormattedNumber(m.mevcutHarcirahTutar) ?? 0) * 20 * 12
        let tHarcirah = (parseFormattedNumber(m.teklifHarcirahTutar) ?? 0) * 20 * 12
        if mHarcirah > 0 || tHarcirah > 0 {
            liste.append(GizliServetKalemi(ikon: "briefcase.fill", baslik: "Harcırah", mevcutDeger: mHarcirah, teklifDeger: tHarcirah))
        }

        return liste
    }

}

// MARK: - Gizli Servet Kalemi (Derin Analiz hesap fişi için)
struct GizliServetKalemi: Identifiable {
    let id = UUID()
    let ikon: String
    let baslik: String
    let mevcutDeger: Double
    let teklifDeger: Double
}

