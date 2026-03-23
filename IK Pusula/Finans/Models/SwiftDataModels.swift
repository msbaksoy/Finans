import Foundation
import SwiftData

// MARK: - SwiftData Models (replacing UserDefaults-backed structs)

@Model
final class AylikMaas: Identifiable {
    var id: UUID
    var ay: Int
    var brutTutar: Double
    var primTutar: Double
    var netTutar: Double
    var yil: Int
    var kesintilerData: Data?

    var kesintiler: [KesintiKalemCodable] {
        get {
            guard let data = kesintilerData else { return [] }
            return (try? JSONDecoder().decode([KesintiKalemCodable].self, from: data)) ?? []
        }
        set {
            kesintilerData = try? JSONEncoder().encode(newValue)
        }
    }

    var brutArtıPrim: Double { brutTutar + primTutar }

    init(
        id: UUID = UUID(),
        ay: Int,
        brutTutar: Double,
        primTutar: Double = 0,
        netTutar: Double,
        kesintiler: [KesintiKalemCodable],
        yil: Int = Calendar.current.component(.year, from: Date())
    ) {
        self.id = id
        self.ay = ay
        self.brutTutar = brutTutar
        self.primTutar = primTutar
        self.netTutar = netTutar
        self.yil = yil
        self.kesintilerData = try? JSONEncoder().encode(kesintiler)
    }
}

// MARK: - Teklif Kıyaslama (TeklifKiyaslama)

enum CalismaModeli: String, Codable, CaseIterable {
    case uzaktan = "Uzaktan (Remote)"
    case hibrit = "Hibrit"
    case ofis = "Ofis"
}

enum KariyerDurumu: String, Codable, CaseIterable {
    case terfi = "Terfi / Üst Ünvan"
    case ayniUnvan = "Aynı Ünvan / Yatay Geçiş"
}

@Model
final class TeklifKiyaslama {
    var id: UUID = UUID()
    var olusturulmaTarihi: Date = Date()
    
    // 1. SORU: Şirket ve Kariyer
    var mevcutSirketAdi: String = ""
    var teklifSirketAdi: String = ""
    var mevcutSehir: String = ""
    var teklifSehir: String = ""
    var terfiVarMi: Bool = false
    var mevcutUnvan: String = ""
    var teklifUnvan: String = ""
    var mevcutUnvanYil: Int = 0
    /// Sorumluluk kademesi: 1 Giriş, 2 Orta, 3 Kıdemli, 4 Yönetim, 5 C-Level
    var mevcutUnvanRank: Int = 1
    var teklifUnvanRank: Int = 1
    
    // 2. SORU: Finansal
    var mevcutBrutMaas: Double = 0
    var mevcutMaasBrutMu: Bool = true   // Mevcut aylık maaş brüt mü, net mi?
    var teklifBrutMaas: Double = 0
    var teklifMaasBrutMu: Bool = true   // Teklif aylık maaş brüt mü, net mi?
    var mevcutMaasSayisi: Int = 12
    var teklifMaasSayisi: Int = 12
    var mevcutPrimTutar: Double = 0
    var mevcutPrimBrutMu: Bool = true
    var teklifPrimTutar: Double = 0
    var teklifPrimBrutMu: Bool = true
    
    // 3. SORU: Çalışma Düzeni & Yol
    var mevcutCalismaModeli: String = ""
    var teklifCalismaModeli: String = ""
    var mevcutOfisGunSayisi: Int = 0
    var teklifOfisGunSayisi: Int = 0
    var mevcutUlasimTipi: String = ""
    var teklifUlasimTipi: String = ""
    var mevcutYolSureDakika: Int = 0
    var teklifYolSureDakika: Int = 0
    var mevcutSirketAraciVarMi: Bool = false
    var teklifSirketAraciVarMi: Bool = false
    
    // 4. SORU: Yan Haklar
    var mevcutYemekTipi: String = "Yok"
    var teklifYemekTipi: String = "Yok"
    var mevcutYemekLezzetYildiz: Int = 0
    var teklifYemekLezzetYildiz: Int = 0
    var mevcutGunlukYemekUcreti: Double = 0
    var teklifGunlukYemekUcreti: Double = 0
    var mevcutSigortaTipi: String = "Yok"
    var teklifSigortaTipi: String = "Yok"
    /// ÖSS/TSS seçilip "Ailemi Kapsıyor" denildiğinde yararlanan kişi sayısı (kullanıcı dahil). 1 = sadece ben.
    var mevcutSigortaYararlananKisiSayisi: Int = 1
    var teklifSigortaYararlananKisiSayisi: Int = 1

    // Eski tek alanlı yapay zeka yorumu (geriye dönük kayıtlar için)
    var aiYorumu: String = ""
    
    // Yeni: Hızlı ve Derin analiz için ayrı yapay zeka yorumları
    var aiHizliYorumu: String = ""
    var aiDerinYorumu: String = ""
    /// Derin analiz formu doldurulup "Analizi Güncelle" yapıldıysa true; aksi halde grafikler 0 ile çizilmesin diye kilit ekranı gösterilir.
    var derinAnalizYapildiMi: Bool = false

    // MARK: - DEEP DIVE (DETAYLI ANALİZ) ALANLARI
    
    // 1. Araç, BES ve Prim Modeli
    var mevcutAracSegment: String = "" // B Segment, C Segment, SUV, Yok vb.
    var teklifAracSegment: String = ""
    var mevcutBesVarMi: Bool = false
    var teklifBesVarMi: Bool = false
    /// İşveren BES katkısının adayın hissettiği aylık toplam TL karşılığı (varsa).
    /// Örn: Maaşın %3'ü yerine doğrudan "1.500 TL/ay" gibi net bir rakam.
    var mevcutBesAylikKatki: String = "" // Aylık ₺
    var teklifBesAylikKatki: String = "" // Aylık ₺
    var mevcutPrimTipi: String = "" // Garanti, Hedef Bazlı, Şirket Karlılığı
    var teklifPrimTipi: String = ""
    
    // 2. Akıllı Ulaşım ve Yakıt
    var mevcutUlasimKalitesi: String = "" // Toplu Taşıma, Servis, Kendi Aracım
    var teklifUlasimKalitesi: String = ""
    var mevcutYakitDestekTipi: String = "" // Limitsiz, Limitli, Yok
    var teklifYakitDestekTipi: String = ""
    var mevcutYakitDestekTutar: String = "" // Aylık ₺
    var teklifYakitDestekTutar: String = ""
    var mevcutTopluTasimaDestekVarMi: Bool = false
    var teklifTopluTasimaDestekVarMi: Bool = false
    var mevcutTopluTasimaTutar: String = "" // Aylık ₺
    var teklifTopluTasimaTutar: String = ""
    /// Kendi aracıyla ulaşım tercih edildiğinde tahmini aylık toplam yakıt/otopark vb. gideri.
    var mevcutKendiAracAylikGider: String = "" // Aylık ₺
    var teklifKendiAracAylikGider: String = "" // Aylık ₺
    /// Bu gideri ağırlıklı olarak kimin karşıladığı bilgisi ("Şirket" / "Ben").
    var mevcutKendiAracGiderKimin: String = ""
    var teklifKendiAracGiderKimin: String = ""
    
    // 3. Nakit Destekler ve Ev Bütçesi
    var mevcutEvInternetTutar: String = "" // Aylık ₺
    var teklifEvInternetTutar: String = ""
    var mevcutFaturaDestegiTutar: String = "" // Aylık ₺ (Elektrik, Su vb.)
    var teklifFaturaDestegiTutar: String = ""
    var mevcutDilTazminatiTutar: String = "" // Aylık ₺
    var teklifDilTazminatiTutar: String = ""
    var mevcutHarcirahTutar: String = "" // Günlük/Aylık ortalama ₺
    var teklifHarcirahTutar: String = ""
    
    // 4. Zaman ve Kariyer Çapı
    var mevcutYillikIzin: Int = 14
    var teklifYillikIzin: Int = 14
    var mevcutMesaiKulturu: String = "" // Ücretli, İzin Veriliyor, Karşılıksız
    var teklifMesaiKulturu: String = ""
    var mevcutEkipYonetimi: String = "" // Yok, 1-5 Kişi, 5+ Kişi
    var teklifEkipYonetimi: String = ""
    var mevcutEgitimButcesi: Bool = false
    var teklifEgitimButcesi: Bool = false
    var mevcutYabanciDil: String = "" // Sürekli Aktif, E-mail / Kısmen, Sadece Lokal
    var teklifYabanciDil: String = ""
    var mevcutSirketOlcegi: String = "" // Startup / KOBİ, Kurumsal / Lokal, Global
    var teklifSirketOlcegi: String = ""

    init(
        id: UUID = UUID(),
        olusturulmaTarihi: Date = Date(),
        mevcutSirketAdi: String = "",
        teklifSirketAdi: String = ""
    ) {
        self.id = id
        self.olusturulmaTarihi = olusturulmaTarihi
        self.mevcutSirketAdi = mevcutSirketAdi
        self.teklifSirketAdi = teklifSirketAdi
    }
}

// MARK: - Migration DTOs (Codable, for decoding from UserDefaults)
enum MigrationDTOs {
    struct AylikMaasDTO: Codable {
        let id: UUID
        let ay: Int
        let brutTutar: Double
        let primTutar: Double
        let netTutar: Double
        let kesintiler: [KesintiKalemCodable]
        let yil: Int
    }
}
