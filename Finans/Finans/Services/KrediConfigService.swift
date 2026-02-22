import Foundation

/// KKDF ve BSMV oranlarını uzaktan çeker; sunucu yoksa cache veya varsayılanları kullanır.
/// Oranları değiştirmek için: GitHub Gist oluşturup URL'yi burada güncelleyin.
final class KrediConfigService: ObservableObject {
    static let shared = KrediConfigService()
    
    /// Config JSON URL — GitHub Gist raw link.
    /// Test için: gist.github.com → Yeni Gist → Dosya: kredi_config.json
    /// İçerik: {"kkdfOrani": 0.15, "bsmvOrani": 0.15}
    /// Create public gist → Raw butonuna tıkla → URL'yi kopyala → aşağıya yapıştır.
    /// Oranları değiştirmek için Gist'i düzenle, uygulamada "Oranları Yenile" tıkla.
    /// Revision hash OLMADAN kullanın — böylece Gist düzenlendiğinde her zaman en güncel veri gelir.
    private let configURL = "https://gist.githubusercontent.com/msbaksoy/6d663a92e0b5b23dffca1d54ca2d6fe8/raw/kredi_config.json"
    
    private let cacheKey = "KrediConfigCache"
    private let cacheDateKey = "KrediConfigCacheDate"
    private let cacheMaxAge: TimeInterval = 60 // Test için 60 sn — yansımayı hemen görmek için
    
    @Published private(set) var config: KrediConfig
    private var refreshTask: Task<Void, Never>?
    
    init() {
        self.config = Self.loadCached() ?? .defaults
        Task { await refresh() }
    }
    
    /// Uzaktan config çek; başarılıysa cache'e yaz. Önceki istek iptal edilir, sadece en son sonuç kullanılır.
    func refresh() async {
        refreshTask?.cancel()
        let task = Task {
            guard !configURL.contains("PLACEHOLDER") else { return }
            let cacheBust = "?t=\(Int(Date().timeIntervalSince1970))"
            guard let url = URL(string: configURL + cacheBust) else { return }
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            do {
                let (data, _) = try await URLSession.shared.data(for: request)
                guard !Task.isCancelled else { return }
                if let parsed = try? JSONDecoder().decode(KrediConfig.self, from: data),
                   parsed.kkdfOrani >= 0, parsed.kkdfOrani <= 1,
                   parsed.bsmvOrani >= 0, parsed.bsmvOrani <= 1 {
                    await MainActor.run {
                        guard !Task.isCancelled else { return }
                        self.config = parsed
                        Self.saveToCache(parsed)
                    }
                }
            } catch {
                // İptal veya ağ hatası
            }
        }
        refreshTask = task
        await task.value
    }
    
    private static func loadCached() -> KrediConfig? {
        guard let data = UserDefaults.standard.data(forKey: "KrediConfigCache"),
              let date = UserDefaults.standard.object(forKey: "KrediConfigCacheDate") as? Date,
              Date().timeIntervalSince(date) < 60,
              let cached = try? JSONDecoder().decode(KrediConfig.self, from: data) else { return nil }
        return cached
    }
    
    private static func saveToCache(_ config: KrediConfig) {
        if let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: "KrediConfigCache")
            UserDefaults.standard.set(Date(), forKey: "KrediConfigCacheDate")
        }
    }
}

// MARK: - Config Model

struct KrediConfig: Codable {
    let kkdfOrani: Double
    let bsmvOrani: Double
    
    static let defaults = KrediConfig(kkdfOrani: 0.15, bsmvOrani: 0.15)
}
