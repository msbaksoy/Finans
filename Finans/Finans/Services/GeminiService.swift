import Foundation

/// Gemini API servisi (ileride kullanım için tutuldu).
final class GeminiService {
    static let shared = GeminiService()
    private init() {}
}

// MARK: - Errors

enum GeminiError: LocalizedError {
    case apiKeyMissing
    case invalidURL
    case invalidResponse
    case apiError(String)
    case emptyResponse
    
    var errorDescription: String? {
        switch self {
        case .apiKeyMissing: return "API anahtarı girilmedi. Lütfen Ayarlar'dan Gemini API anahtarınızı girin."
        case .invalidURL: return "Geçersiz istek."
        case .invalidResponse: return "Sunucudan geçersiz yanıt alındı."
        case .apiError(let msg): return msg
        case .emptyResponse: return "AI'dan boş yanıt alındı."
        }
    }
}
