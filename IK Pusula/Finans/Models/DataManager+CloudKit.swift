import Foundation
import SwiftUI
import SwiftData
import os.log

private let syncLog = Logger(subsystem: "com.musabaksoy.ikpusula", category: "Sync")

// MARK: - DataManager + Senkronizasyon (SyncProvider üzerinden; CloudKit/Firebase vb. soyutlanmış)
@MainActor
extension DataManager {
    private func fetchAylikMaaslarForSync() -> [AylikMaas] {
        (try? modelContext.fetch(FetchDescriptor<AylikMaas>(sortBy: [SortDescriptor(\.yil), SortDescriptor(\.ay)]))) ?? []
    }

    func syncFromCloud() async {
        guard useCloudKit, let provider = syncProvider, await provider.isAvailable() else { return }

        do {
            let cloudAylikMaaslar = try await provider.fetchAylikMaaslar()

            let cloudHasData = !cloudAylikMaaslar.isEmpty
            let localMaaslar = fetchAylikMaaslarForSync()
            let localHasData = !localMaaslar.isEmpty
            let migrated = UserDefaults.standard.bool(forKey: cloudKitMigratedKey)

            if cloudHasData {
                SyncEngine.reconcileAylikMaaslar(cloudDTOs: cloudAylikMaaslar, context: modelContext)
            } else if localHasData && !migrated {
                await uploadToCloud()
                UserDefaults.standard.set(true, forKey: cloudKitMigratedKey)
            }
        } catch {
            syncLog.error("Senkron indirme hatası: \(error.localizedDescription)")
            reportError("Bulut verileri alınamadı. İnternet bağlantınızı kontrol edin.")
        }
    }

    func uploadToCloud() async {
        guard let provider = syncProvider, await provider.isAvailable() else { return }
        do {
            let aylikMaaslar = fetchAylikMaaslarForSync()
            try await provider.saveAylikMaaslar(aylikMaaslar)
        } catch {
            syncLog.error("Senkron yükleme hatası: \(error.localizedDescription)")
            reportError("Veriler buluta yüklenemedi. Yedeklenmedi.")
        }
    }

    func syncToCloud() {
        guard useCloudKit, syncProvider != nil else { return }
        Task {
            guard let provider = syncProvider, await provider.isAvailable() else { return }
            do {
                let aylikMaaslar = fetchAylikMaaslarForSync()
                try await provider.saveAylikMaaslar(aylikMaaslar)
            } catch {
                syncLog.error("Anlık senkron hatası: \(error.localizedDescription)")
                await MainActor.run {
                    reportError("Bulut senkronizasyonu başarısız.")
                }
            }
        }
    }
}
