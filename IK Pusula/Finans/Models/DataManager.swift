import Foundation
import SwiftUI
import SwiftData

/// Koordinatör: migration, sync tetiklemesi ve hata bildirimi.
@MainActor
class DataManager: ObservableObject {
    @Published var lastUserFacingError: String?

    private let container: ModelContainer
    let modelContext: ModelContext
    let syncProvider: SyncProvider?
    let aylikMaaslarKey = "finans_aylik_maaslar"
    let cloudKitMigratedKey = "finans_cloudkit_migrated"
    let swiftDataMigratedKey = "finans_swiftdata_migrated"

    let useCloudKit = false

    static var previewContainer: ModelContainer = {
        let schema = Schema([AylikMaas.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        if let c = try? ModelContainer(for: schema, configurations: [config]) {
            return c
        }
        assertionFailure("Preview ModelContainer olusturulamadi, fallback denenecek.")
        let fallback = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [fallback])
    }()

    init(container: ModelContainer, syncProvider: SyncProvider? = nil) {
        self.container = container
        self.modelContext = ModelContext(container)
        self.syncProvider = syncProvider

        Task { @MainActor in
            self.loadData()
        }
    }

    private func loadData() {
        migrateFromUserDefaultsIfNeeded()
        if useCloudKit, syncProvider != nil {
            Task { await syncFromCloud() }
        }
    }

    private func migrateFromUserDefaultsIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: swiftDataMigratedKey) else { return }

        if let data = UserDefaults.standard.data(forKey: aylikMaaslarKey),
           let decoded = try? JSONDecoder().decode([MigrationDTOs.AylikMaasDTO].self, from: data) {
            for dto in decoded {
                let m = AylikMaas(id: dto.id, ay: dto.ay, brutTutar: dto.brutTutar, primTutar: dto.primTutar, netTutar: dto.netTutar, kesintiler: dto.kesintiler, yil: dto.yil)
                modelContext.insert(m)
            }
            UserDefaults.standard.removeObject(forKey: aylikMaaslarKey)
        }
        
        do {
            try modelContext.save()
            UserDefaults.standard.set(true, forKey: swiftDataMigratedKey)
        } catch {
            lastUserFacingError = "Eski veriler yeni veri tabanına aktarılırken bir hata oluştu. Lütfen uygulamayı yeniden başlatın."
            print("SwiftData migration save error: \\(error)")
        }
    }

    func reportError(_ message: String) {
        lastUserFacingError = message
    }

    func clearLastError() {
        lastUserFacingError = nil
    }

    func refreshFromContext() {
        // Şu anda context odaklı bir yenileme ihtiyacı yok.
    }
}
