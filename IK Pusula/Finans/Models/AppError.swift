import Foundation

/// Uygulama hata türleri — LocalizedError ile kullanıcıya anlamlı mesaj.
enum AppError: LocalizedError {
    case networkError(String)
    case databaseError
    case validationError(String)

    var errorDescription: String? {
        switch self {
        case .networkError(let msg): return "Bağlantı Hatası: \(msg)"
        case .databaseError: return "Veriler kaydedilirken bir sorun oluştu."
        case .validationError(let msg): return msg
        }
    }
}
