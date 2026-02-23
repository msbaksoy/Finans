import Foundation

/// Mevduat stopaj oranlarını uzaktan çeker. Vadeye göre:
/// 0-6 ay: %17,5 | 7-12 ay: %15 | 12+ ay: %10
final class MevduatConfigService: ObservableObject {
    static let shared = MevduatConfigService()
    
    /// GitHub Gist raw URL — Revision hash OLMADAN.
    /// Gist: mevduat_config.json → {"stopaj0_6": 0.175, "stopaj6_12": 0.15, "stopaj12_plus": 0.10}
    /// Revision hash OLMADAN — Gist güncellenince en güncel veri gelsin
    private let configURL = "https://gist.githubusercontent.com/msbaksoy/fd638cd32b52feb2705dbb5da388f976/raw/mevduat_config.json"
    
    @Published private(set) var config: MevduatStopajConfig
    private var refreshTask: Task<Void, Never>?
    
    init() {
        self.config = Self.loadCached() ?? .defaults
        Task { await refresh() }
    }
    
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
                if let parsed = try? JSONDecoder().decode(MevduatStopajConfig.self, from: data),
                   (0...1).contains(parsed.stopaj0_6),
                   (0...1).contains(parsed.stopaj6_12),
                   (0...1).contains(parsed.stopaj12_plus) {
                    await MainActor.run {
                        guard !Task.isCancelled else { return }
                        self.config = parsed
                        Self.saveToCache(parsed)
                    }
                }
            } catch { }
        }
        refreshTask = task
        await task.value
    }
    
    /// Vadeye göre stopaj oranı (0-1 arası, örn. 0.175)
    func stopajOrani(vadeAy: Int) -> Double {
        switch vadeAy {
        case 1...6: return config.stopaj0_6
        case 7...12: return config.stopaj6_12
        default: return vadeAy > 12 ? config.stopaj12_plus : config.stopaj0_6
        }
    }
    
    private static func loadCached() -> MevduatStopajConfig? {
        guard let data = UserDefaults.standard.data(forKey: "MevduatConfigCache"),
              let date = UserDefaults.standard.object(forKey: "MevduatConfigCacheDate") as? Date,
              Date().timeIntervalSince(date) < 86400,
              let cached = try? JSONDecoder().decode(MevduatStopajConfig.self, from: data) else { return nil }
        return cached
    }
    
    private static func saveToCache(_ config: MevduatStopajConfig) {
        if let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: "MevduatConfigCache")
            UserDefaults.standard.set(Date(), forKey: "MevduatConfigCacheDate")
        }
    }
}

struct MevduatStopajConfig: Codable {
    let stopaj0_6: Double   // 6 aya kadar
    let stopaj6_12: Double  // 7-12 ay
    let stopaj12_plus: Double // 1 yıldan uzun
    
    static let defaults = MevduatStopajConfig(stopaj0_6: 0.175, stopaj6_12: 0.15, stopaj12_plus: 0.10)
}
