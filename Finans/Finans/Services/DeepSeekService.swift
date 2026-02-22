import Foundation

/// DeepSeek Chat API ile Yan Hak Analizi yorumu alır.
/// Yeni kullanıcılara 5 milyon ücretsiz token verilir (kredi kartı gerekmez).
/// API anahtarı: platform.deepseek.com
final class DeepSeekService {
    static let shared = DeepSeekService()
    
    private let baseURL = "https://api.deepseek.com/v1/chat/completions"
    private let model = "deepseek-chat"
    private let systemPrompt = """
    Sen bir insan kaynakları ve kariyer danışmanısın. İki iş teklifini (mevcut iş ve yeni teklif) karşılaştırıp Türkçe, net ve kullanıcı dostu bir yorum üretirsin.
    Para birimleri TL'dir. Kısa paragraflar kullan. 2-4 paragraf yeterli.
    Olumlu ve olumsuz noktaları dengeli şekilde vurgula. Kişisel tavsiye niteliğinde yaz.
    """
    
    private init() {}
    
    /// Yan Hak Analizi verilerini DeepSeek'e gönderip yorum alır.
    func fetchYorum(mevcutIs: YanHakVerisi, teklif: YanHakVerisi, apiKey: String) async throws -> String {
        guard !apiKey.isEmpty else {
            throw DeepSeekError.apiKeyMissing
        }
        
        let payload: [String: Any] = [
            "mevcut_is": mevcutIs.karşılastirmaPayload,
            "teklif": teklif.karşılastirmaPayload
        ]
        let jsonData = try JSONSerialization.data(withJSONObject: payload)
        let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
        
        let userPrompt = """
        Aşağıdaki mevcut iş ve yeni teklif verilerini karşılaştırıp 2-4 paragraflık Türkçe bir değerlendirme yaz. TL para birimidir.
        Kıdem tazminatı, maaş farkı, sigorta, yemek, ulaşım, izin gibi yan hakları da dikkate al.
        
        Veri:
        \(jsonString)
        """
        
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt]
            ],
            "max_tokens": 1024,
            "temperature": 0.7
        ]
        
        guard let url = URL(string: baseURL) else {
            throw DeepSeekError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw DeepSeekError.invalidResponse
        }
        
        if http.statusCode != 200 {
            if let errJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw DeepSeekError.apiError(message)
            }
            throw DeepSeekError.apiError("HTTP \(http.statusCode)")
        }
        
        let parsed = try JSONDecoder().decode(DeepSeekResponse.self, from: data)
        guard let text = parsed.choices?.first?.message.content,
              !text.isEmpty else {
            throw DeepSeekError.emptyResponse
        }
        
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Response Models (OpenAI compatible)

private struct DeepSeekResponse: Codable {
    let choices: [Choice]?
    
    struct Choice: Codable {
        let message: Message
    }
    
    struct Message: Codable {
        let content: String?
    }
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
