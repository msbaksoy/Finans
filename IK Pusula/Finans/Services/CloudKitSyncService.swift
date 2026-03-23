import Foundation
import SwiftData
import CloudKit

/// Bulut senkronizasyonu — DataManager'dan bağımsız, sadece sync işini yapar.
@MainActor
final class CloudKitSyncService {
    private let container: CKContainer
    private let database: CKDatabase

    init(containerIdentifier: String = "iCloud.com.musabaksoy.ikpusula") {
        self.container = CKContainer(identifier: containerIdentifier)
        self.database = container.privateCloudDatabase
    }

    /// Tüm verileri senkronize et (ileride DataManager'daki sync mantığı buraya taşınacak).
    func syncAll(context: ModelContext) async {
        print("CloudKit senkronizasyonu başladı...")
        // Sync mantığı buraya taşınacak
    }
}
