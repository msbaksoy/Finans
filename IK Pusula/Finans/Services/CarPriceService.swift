import Foundation

/// Gist JSON formatı: { "A": 24000, "B": 32000, "C": 42000, ... }
/// Tüm segmentler (A, B, C, D, E, F, G, J, M, S) anahtar olarak kullanılır.
private typealias CarPricesGist = [String: Double]

final class CarPriceService {
    static let shared = CarPriceService()
    private init() {}

    private let gistUrl = "https://gist.githubusercontent.com/msbaksoy/94ab31b040b7cc01fbba4d552a134142/raw/gistfile1.txt"

    // İnternet erişilemezse kullanılacak yedek aylık kiralama bedelleri (TL)
    private var cachedPrices: [String: Double] = [
        "A": 24_000, "B": 32_000, "C": 42_000, "D": 70_000, "E": 110_000,
        "F": 220_000, "G": 180_000, "J": 55_000, "M": 65_000, "S": 250_000
    ]

    /// Uygulama ilk açıldığında veya ihtiyaç halinde GitHub Gist'ten güncel fiyatları çeker.
    func fetchPrices() async {
        guard let url = URL(string: gistUrl) else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(CarPricesGist.self, from: data)
            if !decoded.isEmpty {
                self.cachedPrices = decoded
                print("🚗 Araç fiyatları GitHub Gist'ten güncellendi.")
            }
        } catch {
            print("⚠️ Araç fiyatları çekilemedi, yedek fiyatlar kullanılıyor. Hata: \(error.localizedDescription)")
        }
    }

    /// Seçilen araç segmentinin tahmini aylık piyasa kiralama bedelini döndürür.
    /// "Yok" veya boş string için 0 döner. "B Segment" → "B" anahtarı ile aranır; "SUV" → "J" kabul edilir.
    func monthlyPrice(for segment: String) -> Double {
        let key = segment
            .replacingOccurrences(of: " segment", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespaces)
            .uppercased()
        if key.isEmpty { return 0 }
        // Eski draft'larda "SUV" gelebilir; J ile aynı fiyat
        let lookupKey = key == "SUV" ? "J" : key
        return cachedPrices[lookupKey] ?? 0
    }

    /// Tüm segment seçeneklerini (picker için) döndürür.
    static let segmentler: [String] = AracSegmentBilgisi.segmentler
}
