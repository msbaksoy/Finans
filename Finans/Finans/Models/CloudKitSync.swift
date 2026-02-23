import Foundation
import CloudKit

/// CloudKit ile veri senkronizasyonu. UserDefaults yedek olarak kullanılır; CloudKit birincil depolama.
@MainActor
final class CloudKitSync {
    static let shared = CloudKitSync()
    
    private let container: CKContainer
    private let database: CKDatabase
    private let recordType = "FinansData"
    private let jsonField = "jsonData"
    
    private init() {
        container = CKContainer(identifier: "iCloud.com.finans.app")
        database = container.privateCloudDatabase
    }
    
    /// iCloud hesabı mevcut mu
    func isCloudAvailable() async -> Bool {
        do {
            let status = try await container.accountStatus()
            return status == .available
        } catch {
            return false
        }
    }
    
    // MARK: - Fetch
    
    func fetchIncomes() async throws -> [Income] {
        guard let data = try await fetchRecord(named: "incomes") else { return [] }
        return (try? JSONDecoder().decode([Income].self, from: data)) ?? []
    }
    
    func fetchExpenses() async throws -> [Expense] {
        guard let data = try await fetchRecord(named: "expenses") else { return [] }
        return (try? JSONDecoder().decode([Expense].self, from: data)) ?? []
    }
    
    func fetchAssets() async throws -> [Asset] {
        guard let data = try await fetchRecord(named: "assets") else { return [] }
        return (try? JSONDecoder().decode([Asset].self, from: data)) ?? []
    }
    
    func fetchAylikMaaslar() async throws -> [AylikMaas] {
        guard let data = try await fetchRecord(named: "aylikMaaslar") else { return [] }
        return (try? JSONDecoder().decode([AylikMaas].self, from: data)) ?? []
    }
    
    func fetchSettings() async throws -> (customIncomeSources: [String], customExpenseCategories: [String], customAssetTypes: [String]) {
        struct SettingsData: Codable {
            let customIncomeSources: [String]
            let customExpenseCategories: [String]
            let customAssetTypes: [String]
        }
        guard let data = try await fetchRecord(named: "settings") else {
            return ([], [], [])
        }
        let decoded = try? JSONDecoder().decode(SettingsData.self, from: data)
        return (decoded?.customIncomeSources ?? [], decoded?.customExpenseCategories ?? [], decoded?.customAssetTypes ?? [])
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
    
    func saveIncomes(_ items: [Income]) async throws {
        try await saveRecord(named: "incomes", items: items)
    }
    
    func saveExpenses(_ items: [Expense]) async throws {
        try await saveRecord(named: "expenses", items: items)
    }
    
    func saveAssets(_ items: [Asset]) async throws {
        try await saveRecord(named: "assets", items: items)
    }
    
    func saveAylikMaaslar(_ items: [AylikMaas]) async throws {
        try await saveRecord(named: "aylikMaaslar", items: items)
    }
    
    func saveSettings(customIncomeSources: [String], customExpenseCategories: [String], customAssetTypes: [String]) async throws {
        struct SettingsData: Codable {
            let customIncomeSources: [String]
            let customExpenseCategories: [String]
            let customAssetTypes: [String]
        }
        let data = SettingsData(
            customIncomeSources: customIncomeSources,
            customExpenseCategories: customExpenseCategories,
            customAssetTypes: customAssetTypes
        )
        try await saveRecord(named: "settings", items: data)
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
