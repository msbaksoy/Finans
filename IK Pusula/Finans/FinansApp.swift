import SwiftUI
import SwiftData

@main
struct IKPusulaApp: App {
    private static func inMemoryFallbackContainer(for schema: Schema) -> ModelContainer {
        let fallback = ModelConfiguration(isStoredInMemoryOnly: true)
        if let c = try? ModelContainer(for: schema, configurations: [fallback]) {
            return c
        }
        assertionFailure("In-memory fallback container olusturulamadi.")
        return try! ModelContainer(for: schema, configurations: [fallback])
    }

    // MARK: - Güvenli Container Açma
    static let modelContainer: ModelContainer = {
        let schema = Schema([
            AylikMaas.self,
            MulakatOturumu.self
        ])
        let storeURL = URL.documentsDirectory.appendingPathComponent("ikpusula.sqlite")
        let config = ModelConfiguration(url: storeURL)

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            let yedekURL = URL.documentsDirectory.appendingPathComponent("ikpusula_yedek.sqlite")
            let yedekBasarili = yedekAl(kaynak: storeURL, hedef: yedekURL)

            if yedekBasarili {
                silStore(url: storeURL)
                do {
                    let temizContainer = try ModelContainer(
                        for: schema,
                        configurations: [ModelConfiguration(url: storeURL)]
                    )
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        yedekTemizle(url: yedekURL)
                    }
                    return temizContainer
                } catch {
                    assertionFailure("SwiftData ikinci başlatma da başarısız: \(error)")
                    return inMemoryFallbackContainer(for: schema)
                }
            } else {
                silStore(url: storeURL)
                do {
                    return try ModelContainer(
                        for: schema,
                        configurations: [ModelConfiguration(url: storeURL)]
                    )
                } catch {
                    assertionFailure("SwiftData modelContainer açılamadı: \(error.localizedDescription)")
                    return inMemoryFallbackContainer(for: schema)
                }
            }
        }
    }()

    // MARK: - Teklif Container
    static let teklifContainer: ModelContainer = {
        let schema = Schema([TeklifKiyaslama.self])
        let storeURL = URL.documentsDirectory.appendingPathComponent("teklifler.sqlite")
        let config = ModelConfiguration(url: storeURL)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            let yedekURL = URL.documentsDirectory.appendingPathComponent("teklifler_yedek.sqlite")
            let yedekBasarili = yedekAl(kaynak: storeURL, hedef: yedekURL)
            if yedekBasarili {
                silStore(url: storeURL)
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    yedekTemizle(url: yedekURL)
                }
            } else {
                silStore(url: storeURL)
            }
            do {
                return try ModelContainer(
                    for: schema,
                    configurations: [ModelConfiguration(url: storeURL)]
                )
            } catch {
                assertionFailure("SwiftData teklifContainer açılamadı: \(error.localizedDescription)")
                return inMemoryFallbackContainer(for: schema)
            }
        }
    }()

    // MARK: - Dosya Yardımcıları

    /// SQLite + WAL + SHM dosyalarını hedefe kopyalar.
    private static func yedekAl(kaynak: URL, hedef: URL) -> Bool {
        let fm = FileManager.default
        let kaynakBase = kaynak.deletingPathExtension()
        let hedefBase = hedef.deletingPathExtension()
        let ekler = ["", "-wal", "-shm"]
        var basarili = true

        for ek in ekler {
            let ext = ek.isEmpty ? "sqlite" : "sqlite" + ek
            let kaynakDosya = kaynakBase.appendingPathExtension(ext)
            let hedefDosya = hedefBase.appendingPathExtension(ext)

            guard fm.fileExists(atPath: kaynakDosya.path) else { continue }

            do {
                if fm.fileExists(atPath: hedefDosya.path) {
                    try fm.removeItem(at: hedefDosya)
                }
                try fm.copyItem(at: kaynakDosya, to: hedefDosya)
            } catch {
                basarili = false
            }
        }
        return basarili
    }

    /// Store dosyalarını (sqlite + wal + shm) siler.
    private static func silStore(url: URL) {
        let fm = FileManager.default
        let base = url.deletingPathExtension()
        let uzantilar = ["sqlite", "sqlite-wal", "sqlite-shm"]
        for uzanti in uzantilar {
            let u = base.appendingPathExtension(uzanti)
            try? fm.removeItem(at: u)
        }
    }

    private static func yedekTemizle(url: URL) {
        silStore(url: url)
    }

    // MARK: - App Body
    @StateObject private var dataManager = DataManager(
        container: IKPusulaApp.modelContainer,
        syncProvider: nil
    )
    @StateObject private var appTheme = AppTheme()
    @StateObject private var krediConfig = KrediConfigService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
                .environmentObject(appTheme)
                .environmentObject(krediConfig)
                .modelContainer(IKPusulaApp.modelContainer)
                .preferredColorScheme(appTheme.isLight ? .light : .dark)
                .onAppear {
                    _ = IKPusulaApp.teklifContainer
                    MaasAlarmService.shared.setup()
                    Task {
                        await CarPriceService.shared.fetchPrices()
                        await HealthInsurancePriceService.shared.fetchPrices()
                    }
                }
        }
    }
}
