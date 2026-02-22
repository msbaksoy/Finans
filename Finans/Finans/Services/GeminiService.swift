import Foundation

/// Gemini 2.0 Flash API ile Yan Hak Analizi yorumu alır.
final class GeminiService {
    static let shared = GeminiService()
    
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"
    private let systemPrompt = """
    Sen bir insan kaynakları ve kariyer danışmanısın. İki iş teklifini (mevcut iş ve yeni teklif) karşılaştırıp Türkçe, net ve kullanıcı dostu bir yorum üretirsin.
    Para birimleri TL'dir. Kısa paragraflar kullan. 2-4 paragraf yeterli.
    Olumlu ve olumsuz noktaları dengeli şekilde vurgula. Kişisel tavsiye niteliğinde yaz.
    """
    
    private init() {}
    
    /// Yan Hak Analizi verilerini Gemini'ye gönderip yorum alır.
    func fetchYorum(mevcutIs: YanHakVerisi, teklif: YanHakVerisi, apiKey: String) async throws -> String {
        guard !apiKey.isEmpty else {
            throw GeminiError.apiKeyMissing
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
            "systemInstruction": [
                "parts": [["text": systemPrompt]]
            ],
            "contents": [
                [
                    "role": "user",
                    "parts": [["text": userPrompt]]
                ]
            ]
        ]
        
        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            throw GeminiError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }
        
        if http.statusCode != 200 {
            if let errJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw GeminiError.apiError(message)
            }
            throw GeminiError.apiError("HTTP \(http.statusCode)")
        }
        
        let parsed = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard let text = parsed.candidates?.first?.content.parts.first?.text,
              !text.isEmpty else {
            throw GeminiError.emptyResponse
        }
        
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Response Models

private struct GeminiResponse: Codable {
    let candidates: [Candidate]?
    
    struct Candidate: Codable {
        let content: Content
    }
    
    struct Content: Codable {
        let parts: [Part]
    }
    
    struct Part: Codable {
        let text: String
    }
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
