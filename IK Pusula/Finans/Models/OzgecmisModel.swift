// MARK: - Özgeçmiş Modülü — Tamamen bağımsız veri modeli (mevcut CV ile ortak dosya yok)

import Foundation

enum OzgecmisOzetKonum: String, Codable, Equatable {
    case solPanel
    case sagUst
}

/// Tek bir özgeçmiş taslağının tüm alanları
struct OzgecmisDraft: Codable, Equatable {
    var kisisel: OzgecmisKisisel = .init()
    var ozet: String = ""
    /// Profesyonel özetin PDF'te nerede gösterileceği
    var ozetKonum: OzgecmisOzetKonum = .sagUst
    var isDeneyimleri: [OzgecmisDeneyim] = []
    var egitimler: [OzgecmisEgitim] = []
    var yetenekler: [String] = []
    var diller: [OzgecmisDil] = []
    var sertifikalar: [OzgecmisSertifika] = []
    var projeler: [OzgecmisProje] = []
    var referanslar: [OzgecmisReferans] = []
    var oduller: [String] = []
    var hobiler: [String] = []
    var ekBilgiler: String = ""
    /// Sol panel arka plan rengi (hex, örn. "0D3D73"). nil = varsayılan mavi.
    var solPanelRenkHex: String? = nil
}

// MARK: - Kişisel bilgiler
struct OzgecmisKisisel: Codable, Equatable {
    var adSoyad: String = ""
    var email: String = ""
    var telefon: String = ""
    var sehirIlce: String = ""
    var dogumTarihi: String = ""  // serbest metin veya "YYYY"
    var linkedIn: String = ""
    var webSitesi: String = ""
    var ulke: String = ""
    var surucuBelgesi: String = ""
    var askerlikDurumu: String = ""
    /// Tecilli ise "Ay Yıl" formatında tecil bitiş tarihi
    var askerlikTecilBitis: String = ""
    var medeniDurum: String = ""
    var sosyalMedya: String = ""
}

// MARK: - İş deneyimi
struct OzgecmisDeneyim: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var unvan: String = ""
    var sirket: String = ""
    var sehirIlce: String = ""
    var firmaSektoru: String = ""
    var departman: String = ""
    var calismaSekli: String = ""
    var ulke: String = ""
    var baslangic: String = ""  // "Ay Yıl" veya "Yıl"
    var bitis: String = ""
    var halaDevamEdiyor: Bool = false
    var aciklama: String = ""
}

// MARK: - Eğitim
struct OzgecmisEgitim: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var okul: String = ""
    var derece: String = ""   // Lise, Ön Lisans, Lisans, Yüksek Lisans, Doktora
    var bolum: String = ""
    var fakulte: String = ""
    var liseTipi: String = ""
    var liseBolumu: String = ""
    var baslangic: String = ""
    var bitis: String = ""
    var diplomaNotSistemi: String = "" // "4'lük Sistem", "100'lük Sistem"
    var diplomaNotu: String = ""
    var ogretimTipi: String = ""
    var ogretimDili: String = ""
    var bursTipi: String = ""
    var bursOrani: String = ""
    var notOrtalamasi: String = ""
    var aciklama: String = ""
}

// MARK: - Dil
struct OzgecmisDil: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var dilAdi: String = ""
    var seviye: String = ""  // A1, A2, B1, B2, C1, C2, Anadil, vb.
    /// İsteğe bağlı yıldızlı seviye (1–5). 0 veya nil = kullanılmıyor.
    var yildizSeviye: Int? = nil
}

// MARK: - Sertifika / Kurs
struct OzgecmisSertifika: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var ad: String = ""
    var verenKurum: String = ""
    var tarih: String = ""
    var aciklama: String = ""
}

// MARK: - Proje
struct OzgecmisProje: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var projeAdi: String = ""
    var aciklama: String = ""
    var tarih: String = ""
    var link: String = ""
}

// MARK: - Referans
struct OzgecmisReferans: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var adSoyad: String = ""
    var unvan: String = ""
    var firma: String = ""
    var telefon: String = ""
    var email: String = ""
}
