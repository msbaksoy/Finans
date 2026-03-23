// ================================================================
// MulakatModels.swift
// ================================================================
// Mülakat Simülasyonu — veri modelleri ve SwiftData entity
// ================================================================

import Foundation
import SwiftData

// MARK: - Mülakat Modu
enum MulakatModu: String, CaseIterable, Codable {
    case soruCevap    = "Soru–Cevap"
    case senaryo      = "Senaryo"
    case tamSimulasyon = "Tam Simülasyon"

    var aciklama: String {
        switch self {
        case .soruCevap:     return "AI soru sorar, sen cevapla. Her cevaba anlık puan ve öneri."
        case .senaryo:       return "Gerçek iş vakası verilir. STAR yöntemiyle yapılandırılmış cevap ver."
        case .tamSimulasyon: return "AI bir İK uzmanı rolü oynar. Dinamik akış, detaylı final raporu."
        }
    }

    var zorluk: String {
        switch self {
        case .soruCevap:     return "Başlangıç"
        case .senaryo:       return "Orta"
        case .tamSimulasyon: return "İleri"
        }
    }

    var ikon: String {
        switch self {
        case .soruCevap:     return "message.fill"
        case .senaryo:       return "doc.text.fill"
        case .tamSimulasyon: return "person.2.fill"
        }
    }

    var renk: String {
        switch self {
        case .soruCevap:     return "0EA5E9"
        case .senaryo:       return "8B5CF6"
        case .tamSimulasyon: return "EF4444"
        }
    }

    /// Oturumda kaç soru sorulacak
    var soruSayisi: Int {
        switch self {
        case .soruCevap:     return 5
        case .senaryo:       return 3
        case .tamSimulasyon: return 7
        }
    }
}

// MARK: - Soru Kategorisi
enum MulakatSoruKategorisi: String, Codable, CaseIterable {
    case davranissal    = "Davranışsal"
    case teknik         = "Teknik"
    case motivasyon     = "Motivasyon & Hedefler"
    case senaryo        = "Senaryo & Vaka"
    case liderlik       = "Liderlik"
    case iletisim       = "İletişim"

    var ikon: String {
        switch self {
        case .davranissal: return "person.fill.checkmark"
        case .teknik:      return "gearshape.fill"
        case .motivasyon:  return "star.fill"
        case .senaryo:     return "doc.text.fill"
        case .liderlik:    return "crown.fill"
        case .iletisim:    return "bubble.left.and.bubble.right.fill"
        }
    }
}

// MARK: - Tek Soru + Yanıt
struct MulakatSoru: Codable, Identifiable {
    var id: UUID = UUID()
    var siraNo: Int
    var soru: String
    var kategori: MulakatSoruKategorisi
    var kullaniciYaniti: String = ""
    /// AI'ın bu yanıta verdiği puan (0-10)
    var aiPuani: Double?
    /// AI'ın değerlendirme metni
    var aiYorum: String = ""
    /// AI'ın iyileştirme önerileri
    var aiOneri: String = ""
    /// STAR modunda: Durum/Görev/Eylem/Sonuç analizi
    var starAnaliz: STARAnaliz?
}

struct STARAnaliz: Codable {
    var durum: String = ""    // Situation
    var gorev: String = ""    // Task
    var eylem: String = ""    // Action
    var sonuc: String = ""    // Result
    var eksikBileskenler: [String] = []
}

// MARK: - Mülakat Oturumu (SwiftData @Model)
@Model
final class MulakatOturumu {
    var id: UUID
    var olusturmaTarihi: Date
    var pozisyon: String
    var hedefSirket: String
    var sektor: String
    var mod: String          // MulakatModu.rawValue
    var tamamlandi: Bool
    var sorularData: Data    // [MulakatSoru] JSON
    var toplamPuan: Double
    var aiGenelYorum: String
    var aiGucluYonler: [String]
    var aiGelistirilecek: [String]
    var sureDakika: Int

    init(
        pozisyon: String,
        hedefSirket: String,
        sektor: String,
        mod: MulakatModu
    ) {
        self.id                = UUID()
        self.olusturmaTarihi   = Date()
        self.pozisyon          = pozisyon
        self.hedefSirket       = hedefSirket
        self.sektor            = sektor
        self.mod               = mod.rawValue
        self.tamamlandi        = false
        self.sorularData       = Data()
        self.toplamPuan        = 0
        self.aiGenelYorum      = ""
        self.aiGucluYonler     = []
        self.aiGelistirilecek  = []
        self.sureDakika        = 0
    }

    var moduEnum: MulakatModu {
        MulakatModu(rawValue: mod) ?? .soruCevap
    }

    var sorular: [MulakatSoru] {
        get {
            (try? JSONDecoder().decode([MulakatSoru].self, from: sorularData)) ?? []
        }
        set {
            sorularData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    var ortalamaPuan: Double {
        let puanlilar = sorular.compactMap { $0.aiPuani }
        guard !puanlilar.isEmpty else { return 0 }
        return puanlilar.reduce(0, +) / Double(puanlilar.count)
    }

    var tarihFormatlı: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateFormat = "d MMMM yyyy · HH:mm"
        return f.string(from: olusturmaTarihi)
    }
}

// MARK: - Puan Rengi
extension Double {
    var mulakatPuanRengi: String {
        if self >= 8.0 { return "10B981" }  // yeşil
        if self >= 6.0 { return "F59E0B" }  // turuncu
        return "EF4444"                      // kırmızı
    }

    var mulakatPuanEtiketi: String {
        if self >= 9.0 { return "Mükemmel" }
        if self >= 7.5 { return "Çok İyi" }
        if self >= 6.0 { return "İyi" }
        if self >= 4.0 { return "Geliştirilmeli" }
        return "Yetersiz"
    }
}
