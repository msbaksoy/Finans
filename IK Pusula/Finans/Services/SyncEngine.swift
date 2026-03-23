import Foundation
import SwiftData

/// Bulut verisini yerel ile birleştirir — sil-yaz yerine upsert (ID ile güncelle veya ekle).
@MainActor
enum SyncEngine {

    static func reconcileAylikMaaslar(cloudDTOs: [MigrationDTOs.AylikMaasDTO], context: ModelContext) {
        for dto in cloudDTOs {
            let id = dto.id
            var descriptor = FetchDescriptor<AylikMaas>(predicate: #Predicate<AylikMaas> { $0.id == id })
            descriptor.fetchLimit = 1
            if let existing = try? context.fetch(descriptor).first {
                existing.ay = dto.ay
                existing.brutTutar = dto.brutTutar
                existing.primTutar = dto.primTutar
                existing.netTutar = dto.netTutar
                existing.kesintiler = dto.kesintiler
                existing.yil = dto.yil
            } else {
                context.insert(AylikMaas(id: dto.id, ay: dto.ay, brutTutar: dto.brutTutar, primTutar: dto.primTutar, netTutar: dto.netTutar, kesintiler: dto.kesintiler, yil: dto.yil))
            }
        }
        try? context.save()
    }
}
