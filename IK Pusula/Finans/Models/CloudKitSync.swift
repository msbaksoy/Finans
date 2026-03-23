import Foundation
import CloudKit
import os.log

private let ckSyncLog = Logger(subsystem: "com.musabaksoy.ikpusula", category: "CloudKitSync")

/// CloudKit ile veri senkronizasyonu (SyncProvider uygulaması).
@MainActor
final class CloudKitSync: SyncProvider {
    static let shared = CloudKitSync()

    private let container: CKContainer
    private let database: CKDatabase
    private let recordType = "IKPusulaData"
    private let jsonField = "jsonData"

    private init() {
        container = CKContainer(identifier: "iCloud.com.musabaksoy.ikpusula")
        database = container.privateCloudDatabase
    }

    func isAvailable() async -> Bool {
        do {
            let status = try await container.accountStatus()
            return status == .available
        } catch {
            ckSyncLog.error("iCloud hesap durumu hatası: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Fetch (returns DTOs for SwiftData migration)
    
    func fetchAylikMaaslar() async throws -> [MigrationDTOs.AylikMaasDTO] {
        guard let data = try await fetchRecord(named: "aylikMaaslar") else { return [] }
        return (try? JSONDecoder().decode([MigrationDTOs.AylikMaasDTO].self, from: data)) ?? []
    }
    
    private func fetchRecord(named name: String) async throws -> Data? {
        let recordID = CKRecord.ID(recordName: name, zoneID: CKRecordZone.default().zoneID)
        do {
            let record = try await database.record(for: recordID)
            guard let json = record[jsonField] as? String else { return nil }
            return json.data(using: .utf8)
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        }
    }
    
    // MARK: - Save
    
    func saveAylikMaaslar(_ items: [AylikMaas]) async throws {
        let dtos = items.map { MigrationDTOs.AylikMaasDTO(id: $0.id, ay: $0.ay, brutTutar: $0.brutTutar, primTutar: $0.primTutar, netTutar: $0.netTutar, kesintiler: $0.kesintiler, yil: $0.yil) }
        try await saveRecord(named: "aylikMaaslar", items: dtos)
    }
    
    private func saveRecord<T: Encodable>(named name: String, items: T) async throws {
        let data = try JSONEncoder().encode(items)
        guard let json = String(data: data, encoding: .utf8) else { return }
        
        let recordID = CKRecord.ID(recordName: name, zoneID: CKRecordZone.default().zoneID)
        
        do {
            let record = try await database.record(for: recordID)
            record[jsonField] = json
            _ = try await database.save(record)
        } catch let error as CKError where error.code == .unknownItem {
            let record = CKRecord(recordType: recordType, recordID: recordID)
            record[jsonField] = json
            _ = try await database.save(record)
        }
    }
}
