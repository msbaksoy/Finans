import Foundation

/// Groq API servisi (ileride kullanım için tutuldu).
final class GroqService {
    static let shared = GroqService()
    private init() {}
}

// MARK: - Errors

enum GroqError: LocalizedError {
    case apiKeyMissing
    case invalidURL
    case invalidResponse
    case apiError(String)
    case emptyResponse
    
    var errorDescription: String? {
        switch self {
        case .apiKeyMissing: return "API anahtarı girilmedi. console.groq.com adresinden ücretsiz anahtar alın."
        case .invalidURL: return "Geçersiz istek."
        case .invalidResponse: return "Sunucudan geçersiz yanıt alındı."
        case .apiError(let msg): return msg
        case .emptyResponse: return "AI'dan boş yanıt alındı."
        }
    }
}
