import Foundation

// MARK: - Kesinti Kalemi
struct KesintiKalemi: Identifiable {
    let id = UUID()
    let ad: String
    let tutar: Double
    let oran: Double? // Yüzde olarak (opsiyonel)
}

// AylikMaas is now an @Model class in SwiftDataModels.swift

struct KesintiKalemCodable: Codable {
    let ad: String
    let tutar: Double
    let oran: Double?
}

// MARK: - Aylık Detaylı Brüt-Net (tablo gösterimi için)
struct AylikBrutNetDetay: Identifiable {
    let id = UUID()
    let ay: Int
    let brut: Double       // Brüt maaş
    let prim: Double       // Prim
    let sgkIsci: Double
    let issizlikIsci: Double
    let aylikGelirVergisi: Double
    let damgaVergisi: Double
    let kumulatifVergiMatrahi: Double
    let netVergiOncesi: Double
    let agi: Double  // Her zaman 0
    let asgariUcretGVIstisnasi: Double
    let asgariUcretDVIstisnasi: Double
    let toplamNetEleGecen: Double
    let sgkIsveren: Double
    let issizlikIsveren: Double
    let toplamMaliyet: Double
    
    /// Brüt maaş + Prim toplamı (tabloda tek sütunda gösterilir)
    var brutToplam: Double {
        return brut + prim
    }
}

/// Tek ay hesaplama çıktısı (BrutNetCalculator.hesapla)
struct MaasSonuc {
    let net: Double
    let vergi: Double       // Ödenecek gelir vergisi
    let sgk: Double         // Toplam SGK+işsizlik işçi payı
    let damga: Double       // Ödenecek damga vergisi
    let avantaj: Double     // Asgari ücret GV+DV istisnası toplamı
    let maliyet: Double     // İşveren toplam maliyeti
}

// MARK: - Ay ismi (Locale’e göre)
enum Aylar {
    static func isim(ay: Int) -> String {
        guard ay >= 1, ay <= 12 else { return "" }
        return Calendar.current.monthSymbols[ay - 1].capitalized
    }
}
