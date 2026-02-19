import Foundation

// MARK: - Kesinti Kalemi
struct KesintiKalemi: Identifiable {
    let id = UUID()
    let ad: String
    let tutar: Double
    let oran: Double? // Yüzde olarak (opsiyonel)
}

// MARK: - Aylık Maaş
struct AylikMaas: Identifiable, Codable {
    let id: UUID
    let ay: Int // 1-12
    var brutTutar: Double
    var netTutar: Double
    var kesintiler: [KesintiKalemCodable]
    let yil: Int
    
    init(id: UUID = UUID(), ay: Int, brutTutar: Double, netTutar: Double, kesintiler: [KesintiKalemCodable], yil: Int = Calendar.current.component(.year, from: Date())) {
        self.id = id
        self.ay = ay
        self.brutTutar = brutTutar
        self.netTutar = netTutar
        self.kesintiler = kesintiler
        self.yil = yil
    }
}

struct KesintiKalemCodable: Codable {
    let ad: String
    let tutar: Double
    let oran: Double?
}

// MARK: - Aylık Detaylı Brüt-Net (tablo gösterimi için)
struct AylikBrutNetDetay: Identifiable {
    let id = UUID()
    let ay: Int
    let brut: Double
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
}

// MARK: - Ay İsimleri
let ayIsimleri = ["Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran", "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"]
