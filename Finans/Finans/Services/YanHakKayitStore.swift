import Foundation

/// Kaydedilmiş Yan Hak Analizi kaydı
struct YanHakKayit: Identifiable, Codable {
    var id: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date
    var mevcutIs: YanHakVerisi
    var teklif: YanHakVerisi
    
    init(id: UUID = UUID(), name: String, createdAt: Date = Date(), updatedAt: Date = Date(), mevcutIs: YanHakVerisi, teklif: YanHakVerisi) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.mevcutIs = mevcutIs
        self.teklif = teklif
    }
}

/// Kaydedilmiş Yan Hak Analizleri — UserDefaults
final class YanHakKayitStore: ObservableObject {
    static let shared = YanHakKayitStore()
    private let key = "yan_hak_kayitlari"
    
    @Published private(set) var kayitlar: [YanHakKayit] = []
    
    private init() {
        yukle()
    }
    
    private func yukle() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([YanHakKayit].self, from: data) else {
            kayitlar = []
            return
        }
        kayitlar = decoded
    }
    
    func kaydet(_ kayit: YanHakKayit) {
        var list = kayitlar
        if let idx = list.firstIndex(where: { $0.id == kayit.id }) {
            var guncel = kayit
            guncel.updatedAt = Date()
            list[idx] = guncel
        } else {
            list.insert(kayit, at: 0)
        }
        kayitlar = list
        persist()
    }
    
    func sil(id: UUID) {
        kayitlar.removeAll { $0.id == id }
        persist()
    }
    
    private func persist() {
        guard let data = try? JSONEncoder().encode(kayitlar) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
