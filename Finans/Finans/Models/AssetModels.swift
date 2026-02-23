import Foundation

// MARK: - Varlık Türleri
enum AssetType: String, CaseIterable, Codable {
    case bond = "Tahvil"
    case bankDeposit = "Banka Mevduatı"
    case stock = "Hisse Senedi"
    case etf = "Borsa Yatırım Fonu (ETF)"
    case mutualFund = "Yatırım Fonu"
    case gold = "Altın / Değerli Maden"
    case crypto = "Kripto Para"
    case pension = "Emeklilik"
    case realEstate = "Gayrimenkul"
    case other = "Diğer"
    
    var isQuantityBased: Bool {
        self == .stock || self == .etf || self == .crypto
    }
    
    var supportsQuantityAndPrice: Bool {
        isQuantityBased
    }
}

// MARK: - Varlık
struct Asset: Identifiable, Codable {
    let id: UUID
    let type: AssetType
    let typeName: String  // "Diğer" için özel isim
    let name: String      // Hisse adı, hesap adı vb.
    let quantity: Double? // Hisse/kripto için adet
    let pricePerUnit: Double? // Hisse/kripto için birim fiyat
    let totalAmount: Double? // Sabit varlıklar için toplam tutar
    let dateAdded: Date
    
    init(
        id: UUID = UUID(),
        type: AssetType,
        typeName: String,
        name: String,
        quantity: Double? = nil,
        pricePerUnit: Double? = nil,
        totalAmount: Double? = nil,
        dateAdded: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.typeName = typeName
        self.name = name
        self.quantity = quantity
        self.pricePerUnit = pricePerUnit
        self.totalAmount = totalAmount
        self.dateAdded = dateAdded
    }
    
    /// Toplam değer - hisse için: adet × fiyat, diğerleri için: toplam tutar
    var totalValue: Double {
        if type.supportsQuantityAndPrice, let q = quantity, let p = pricePerUnit {
            return q * p
        }
        return totalAmount ?? 0
    }
    
    /// Gösterim için varlık türü adı
    var displayType: String {
        type == .other ? typeName : type.rawValue
    }
}
