import Foundation

struct HealthInsurancePrices: Codable {
    let oss: Double
    let tss: Double
    
    enum CodingKeys: String, CodingKey {
        case oss = "OSS"
        case tss = "TSS"
    }
}

/// Sağlık sigortası (ÖSS / TSS) yıllık paket değerlerini GitHub Gist üzerinden yöneten servis.
final class HealthInsurancePriceService {
    static let shared = HealthInsurancePriceService()
    private init() {}
    
    // Kullanıcının paylaştığı Gist (OSS / TSS yıllık değerleri)
    // İçerik örneği:
    // { "OSS": 90000, "TSS": 20000 }
    private let gistUrl = "https://gist.githubusercontent.com/msbaksoy/cdd6c50f79aedf737d8d1dc95437a9f4/raw/gistfile1.txt"
    
    // İnternet erişilemezse kullanılacak yedek yıllık paket değerleri (TL)
    private var cachedPrices = HealthInsurancePrices(
        oss: 90_000,
        tss: 20_000
    )
    
    /// Uygulama ilk açıldığında veya ihtiyaç halinde GitHub Gist'ten güncel sağlık sigortası fiyatlarını çeker.
    func fetchPrices() async {
        guard let url = URL(string: gistUrl) else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(HealthInsurancePrices.self, from: data)
            self.cachedPrices = decoded
            print("🩺 Sağlık sigortası fiyatları GitHub Gist'ten güncellendi.")
        } catch {
            print("⚠️ Sağlık sigortası fiyatları çekilemedi, yedek değerler kullanılıyor. Hata: \(error.localizedDescription)")
        }
    }
    
    /// Sigorta tipine göre yıllık paket değerini döndürür.
    /// - Parameter sigortaTipi: "Özel", "Tamamlayıcı" veya diğerleri.
    func yearlyPrice(for sigortaTipi: String) -> Double {
        switch sigortaTipi {
        case "Özel":
            return cachedPrices.oss
        case "Tamamlayıcı":
            return cachedPrices.tss
        default:
            return 0
        }
    }
}

