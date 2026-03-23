import Foundation

/// Senkronizasyon sağlayıcı arayüzü (Repository Pattern).
/// Uygulama sadece "senkronize et" der; arkada CloudKit, Firebase veya özel sunucu olabilir.
@MainActor
protocol SyncProvider: AnyObject {
    /// Senkronizasyon backend'i kullanılabilir mi (örn. iCloud girişi, ağ).
    func isAvailable() async -> Bool

    func fetchAylikMaaslar() async throws -> [MigrationDTOs.AylikMaasDTO]

    func saveAylikMaaslar(_ items: [AylikMaas]) async throws
}
