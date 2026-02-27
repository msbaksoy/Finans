import Foundation

/// DeepSeek API servisi (ileride kullanım için tutuldu).
final class DeepSeekService {
    static let shared = DeepSeekService()
    private init() {}
}

// MARK: - Errors

enum DeepSeekError: LocalizedError {
    case apiKeyMissing
    case invalidURL
    case invalidResponse
    case apiError(String)
    case emptyResponse
    
    var errorDescription: String? {
        switch self {
        case .apiKeyMissing: return "API anahtarı girilmedi. platform.deepseek.com adresinden ücretsiz anahtar alın."
        case .invalidURL: return "Geçersiz istek."
        case .invalidResponse: return "Sunucudan geçersiz yanıt alındı."
        case .apiError(let msg): return msg
        case .emptyResponse: return "AI'dan boş yanıt alındı."
        }
    }
}
