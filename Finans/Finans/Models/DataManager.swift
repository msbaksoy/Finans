import Foundation
import SwiftUI

@MainActor
class DataManager: ObservableObject {
    static let shared = DataManager()
    
    @Published var incomes: [Income] = []
    @Published var expenses: [Expense] = []
    @Published var assets: [Asset] = []
    @Published var customIncomeSources: [String] = []
    @Published var customExpenseCategories: [String] = []
    @Published var customAssetTypes: [String] = []
    @Published var aylikMaaslar: [AylikMaas] = []
    
    private let incomesKey = "finans_incomes"
    private let expensesKey = "finans_expenses"
    private let assetsKey = "finans_assets"
    private let customIncomeKey = "finans_custom_income_sources"
    private let customExpenseKey = "finans_custom_expense_categories"
    private let customAssetTypesKey = "finans_custom_asset_types"
    private let aylikMaaslarKey = "finans_aylik_maaslar"
    private let cloudKitMigratedKey = "finans_cloudkit_migrated"
    
    private let cloudKit = CloudKitSync.shared
    
    init() {
        loadData()
    }
    
    private func loadData() {
        // Önce UserDefaults'tan yükle (hızlı başlangıç, offline desteği)
        loadFromUserDefaults()
        
        // CloudKit'dan senkronize et (background)
        Task {
            await syncFromCloudKit()
        }
    }
    
    private func loadFromUserDefaults() {
        if let data = UserDefaults.standard.data(forKey: incomesKey),
           let decoded = try? JSONDecoder().decode([Income].self, from: data) {
            incomes = decoded
        }
        
        if let data = UserDefaults.standard.data(forKey: expensesKey),
           let decoded = try? JSONDecoder().decode([Expense].self, from: data) {
            expenses = decoded
        }
        
        if let sources = UserDefaults.standard.stringArray(forKey: customIncomeKey) {
            customIncomeSources = sources
        }
        
        if let categories = UserDefaults.standard.stringArray(forKey: customExpenseKey) {
            customExpenseCategories = categories
        }
        
        if let data = UserDefaults.standard.data(forKey: assetsKey),
           let decoded = try? JSONDecoder().decode([Asset].self, from: data) {
            assets = decoded
        }
        
        if let types = UserDefaults.standard.stringArray(forKey: customAssetTypesKey) {
            customAssetTypes = types
        }
        
        if let data = UserDefaults.standard.data(forKey: aylikMaaslarKey),
           let decoded = try? JSONDecoder().decode([AylikMaas].self, from: data) {
            aylikMaaslar = decoded
        }
    }
    
    private func syncFromCloudKit() async {
        guard await cloudKit.isCloudAvailable() else { return }
        
        do {
            let cloudIncomes = try await cloudKit.fetchIncomes()
            let cloudExpenses = try await cloudKit.fetchExpenses()
            let cloudAssets = try await cloudKit.fetchAssets()
            let cloudAylikMaaslar = try await cloudKit.fetchAylikMaaslar()
            let (cloudSources, cloudCategories, cloudTypes) = try await cloudKit.fetchSettings()
            
            let cloudHasData = !cloudIncomes.isEmpty || !cloudExpenses.isEmpty || !cloudAssets.isEmpty || !cloudAylikMaaslar.isEmpty || !cloudSources.isEmpty || !cloudCategories.isEmpty || !cloudTypes.isEmpty
            let localHasData = !incomes.isEmpty || !expenses.isEmpty || !assets.isEmpty || !aylikMaaslar.isEmpty || !customIncomeSources.isEmpty || !customExpenseCategories.isEmpty || !customAssetTypes.isEmpty
            let migrated = UserDefaults.standard.bool(forKey: cloudKitMigratedKey)
            
            if cloudHasData {
                // CloudKit'da veri var: CloudKit'ı kullan, UserDefaults'a önbelleğe al
                incomes = cloudIncomes
                expenses = cloudExpenses
                assets = cloudAssets
                aylikMaaslar = cloudAylikMaaslar
                customIncomeSources = cloudSources
                customExpenseCategories = cloudCategories
                customAssetTypes = cloudTypes
                saveAllToUserDefaults()
            } else if localHasData && !migrated {
                // Yerel veri var, CloudKit boş: Migrasyon - yerel veriyi CloudKit'a yükle
                await uploadToCloudKit()
                UserDefaults.standard.set(true, forKey: cloudKitMigratedKey)
            }
        } catch {
            // CloudKit başarısız (ağ, hesap vb.): UserDefaults'taki verilerle devam
        }
    }
    
    private func saveAllToUserDefaults() {
        if let encoded = try? JSONEncoder().encode(incomes) {
            UserDefaults.standard.set(encoded, forKey: incomesKey)
        }
        if let encoded = try? JSONEncoder().encode(expenses) {
            UserDefaults.standard.set(encoded, forKey: expensesKey)
        }
        if let encoded = try? JSONEncoder().encode(assets) {
            UserDefaults.standard.set(encoded, forKey: assetsKey)
        }
        if let encoded = try? JSONEncoder().encode(aylikMaaslar) {
            UserDefaults.standard.set(encoded, forKey: aylikMaaslarKey)
        }
        UserDefaults.standard.set(customIncomeSources, forKey: customIncomeKey)
        UserDefaults.standard.set(customExpenseCategories, forKey: customExpenseKey)
        UserDefaults.standard.set(customAssetTypes, forKey: customAssetTypesKey)
    }
    
    private func uploadToCloudKit() async {
        guard await cloudKit.isCloudAvailable() else { return }
        do {
            try await cloudKit.saveIncomes(incomes)
            try await cloudKit.saveExpenses(expenses)
            try await cloudKit.saveAssets(assets)
            try await cloudKit.saveAylikMaaslar(aylikMaaslar)
            try await cloudKit.saveSettings(customIncomeSources: customIncomeSources, customExpenseCategories: customExpenseCategories, customAssetTypes: customAssetTypes)
        } catch { }
    }
    
    private func syncToCloudKit() {
        Task {
            guard await cloudKit.isCloudAvailable() else { return }
            do {
                try await cloudKit.saveIncomes(incomes)
                try await cloudKit.saveExpenses(expenses)
                try await cloudKit.saveAssets(assets)
                try await cloudKit.saveAylikMaaslar(aylikMaaslar)
                try await cloudKit.saveSettings(customIncomeSources: customIncomeSources, customExpenseCategories: customExpenseCategories, customAssetTypes: customAssetTypes)
            } catch { }
        }
    }
    
    // MARK: - Gelir / Gider
    
    func addIncome(_ income: Income) {
        incomes.append(income)
        saveIncomes()
        syncToCloudKit()
    }
    
    func addExpense(_ expense: Expense) {
        expenses.append(expense)
        saveExpenses()
        syncToCloudKit()
    }
    
    func addCustomIncomeSource(_ source: String) {
        let trimmed = source.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !customIncomeSources.contains(trimmed) else { return }
        customIncomeSources.append(trimmed)
        UserDefaults.standard.set(customIncomeSources, forKey: customIncomeKey)
        syncToCloudKit()
    }
    
    func addCustomExpenseCategory(_ category: String) {
        let trimmed = category.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !customExpenseCategories.contains(trimmed) else { return }
        customExpenseCategories.append(trimmed)
        UserDefaults.standard.set(customExpenseCategories, forKey: customExpenseKey)
        syncToCloudKit()
    }
    
    func deleteIncome(at offsets: IndexSet) {
        incomes.remove(atOffsets: offsets)
        saveIncomes()
        syncToCloudKit()
    }
    
    func deleteExpense(at offsets: IndexSet) {
        expenses.remove(atOffsets: offsets)
        saveExpenses()
        syncToCloudKit()
    }
    
    var totalIncome: Double {
        incomes.reduce(0) { $0 + $1.amount }
    }
    
    var totalExpense: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
    
    var balance: Double {
        totalIncome - totalExpense
    }
    
    var allIncomeSources: [String] {
        IncomeSource.allCases.map { $0.rawValue }.filter { $0 != "Diğer" } + customIncomeSources + ["Diğer"]
    }
    
    var allExpenseCategories: [String] {
        ExpenseCategory.allCases.map { $0.rawValue }.filter { $0 != "Diğer" } + customExpenseCategories + ["Diğer"]
    }
    
    private func saveIncomes() {
        if let encoded = try? JSONEncoder().encode(incomes) {
            UserDefaults.standard.set(encoded, forKey: incomesKey)
        }
    }
    
    private func saveExpenses() {
        if let encoded = try? JSONEncoder().encode(expenses) {
            UserDefaults.standard.set(encoded, forKey: expensesKey)
        }
    }
    
    func saveIncomesIfNeeded() {
        saveIncomes()
        syncToCloudKit()
    }
    
    func saveExpensesIfNeeded() {
        saveExpenses()
        syncToCloudKit()
    }
    
    // MARK: - Portföy
    
    func addAsset(_ asset: Asset) {
        assets.append(asset)
        saveAssets()
        syncToCloudKit()
    }
    
    func updateAsset(_ asset: Asset) {
        if let idx = assets.firstIndex(where: { $0.id == asset.id }) {
            assets[idx] = asset
            saveAssets()
            syncToCloudKit()
        }
    }
    
    func deleteAsset(_ asset: Asset) {
        assets.removeAll { $0.id == asset.id }
        saveAssets()
        syncToCloudKit()
    }
    
    func addCustomAssetType(_ type: String) {
        let trimmed = type.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !customAssetTypes.contains(trimmed) else { return }
        customAssetTypes.append(trimmed)
        UserDefaults.standard.set(customAssetTypes, forKey: customAssetTypesKey)
        syncToCloudKit()
    }
    
    var totalPortfolioValue: Double {
        assets.reduce(0) { $0 + $1.totalValue }
    }
    
    var allAssetTypes: [String] {
        AssetType.allCases.map { $0.rawValue }.filter { $0 != "Diğer" } + customAssetTypes + ["Diğer"]
    }
    
    private func saveAssets() {
        if let encoded = try? JSONEncoder().encode(assets) {
            UserDefaults.standard.set(encoded, forKey: assetsKey)
        }
    }
    
    // MARK: - Brütten Nete
    
    func getAylikMaas(ay: Int, yil: Int) -> AylikMaas? {
        aylikMaaslar.first { $0.ay == ay && $0.yil == yil }
    }
    
    func setAylikMaas(_ maas: AylikMaas) {
        if let idx = aylikMaaslar.firstIndex(where: { $0.ay == maas.ay && $0.yil == maas.yil }) {
            aylikMaaslar[idx] = maas
        } else {
            aylikMaaslar.append(maas)
        }
        saveAylikMaaslar()
        syncToCloudKit()
    }
    
    func tumAylariDoldur(brut: Double, yil: Int) {
        let brutlar = Array(repeating: brut, count: 12)
        let sonuclar = BrutNetCalculator.hesaplaYillik(brutlar: brutlar)
        
        for (index, sonuc) in sonuclar.enumerated() {
            let ay = index + 1
            let kesintiCodable = sonuc.kesintiler.map { KesintiKalemCodable(ad: $0.ad, tutar: $0.tutar, oran: $0.oran) }
            let maas = AylikMaas(ay: ay, brutTutar: brut, netTutar: sonuc.net, kesintiler: kesintiCodable, yil: yil)
            setAylikMaas(maas)
        }
    }
    
    func ayGuncelle(ay: Int, brut: Double, yil: Int) {
        let oncekiAylarBrut = (1..<ay).compactMap { getAylikMaas(ay: $0, yil: yil)?.brutTutar }
        let sonuc = BrutNetCalculator.hesapla(brut: brut, ay: ay, oncekiAylarBrutlari: oncekiAylarBrut)
        let kesintiCodable = sonuc.kesintiler.map { KesintiKalemCodable(ad: $0.ad, tutar: $0.tutar, oran: $0.oran) }
        let maas = AylikMaas(ay: ay, brutTutar: brut, netTutar: sonuc.net, kesintiler: kesintiCodable, yil: yil)
        setAylikMaas(maas)
    }
    
    func oncekiAylarinBrutlari(ay: Int, yil: Int) -> [Double] {
        (1..<ay).compactMap { getAylikMaas(ay: $0, yil: yil)?.brutTutar }
    }
    
    private func saveAylikMaaslar() {
        if let encoded = try? JSONEncoder().encode(aylikMaaslar) {
            UserDefaults.standard.set(encoded, forKey: aylikMaaslarKey)
        }
    }
    
    func brutNetVerileriniTemizle() {
        aylikMaaslar = []
        saveAylikMaaslar()
        syncToCloudKit()
    }
}
