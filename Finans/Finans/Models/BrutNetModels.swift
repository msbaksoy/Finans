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
    var primTutar: Double  // Aylık prim (isteğe bağlı, herhangi bir aya yatabilir)
    var netTutar: Double
    var kesintiler: [KesintiKalemCodable]
    let yil: Int
    
    enum CodingKeys: String, CodingKey {
        case id, ay, brutTutar, primTutar, netTutar, kesintiler, yil
    }
    
    init(id: UUID = UUID(), ay: Int, brutTutar: Double, primTutar: Double = 0, netTutar: Double, kesintiler: [KesintiKalemCodable], yil: Int = Calendar.current.component(.year, from: Date())) {
        self.id = id
        self.ay = ay
        self.brutTutar = brutTutar
        self.primTutar = primTutar
        self.netTutar = netTutar
        self.kesintiler = kesintiler
        self.yil = yil
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        ay = try c.decode(Int.self, forKey: .ay)
        brutTutar = try c.decode(Double.self, forKey: .brutTutar)
        primTutar = try c.decodeIfPresent(Double.self, forKey: .primTutar) ?? 0
        netTutar = try c.decode(Double.self, forKey: .netTutar)
        kesintiler = try c.decode([KesintiKalemCodable].self, forKey: .kesintiler)
        yil = try c.decode(Int.self, forKey: .yil)
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(ay, forKey: .ay)
        try c.encode(brutTutar, forKey: .brutTutar)
        try c.encode(primTutar, forKey: .primTutar)
        try c.encode(netTutar, forKey: .netTutar)
        try c.encode(kesintiler, forKey: .kesintiler)
        try c.encode(yil, forKey: .yil)
    }
    
    /// Brüt + Prim toplamı (SGK matrah hesabı için)
    var brutArtıPrim: Double { brutTutar + primTutar }
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
    
    /// Brüt maaş + Prim toplamı
    var brutToplam: Double { brut + prim }
}

// MARK: - Ay İsimleri
let ayIsimleri = ["Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran", "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"]
