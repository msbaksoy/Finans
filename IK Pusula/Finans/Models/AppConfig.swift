import Foundation

/// Uygulama genelinde kullanılan URL ve sabitler.
enum AppConfig {
    /// Kripto para listesi (code, short_name) — Gist.
    static let kriptoListGistURL = "https://gist.githubusercontent.com/msbaksoy/c25922be2822fe80c1054d71367733d6/raw/gistfile1.txt"
}

// MARK: - OpenAI API (CV otomatik doldurma)
/// API anahtarını test için buraya yapıştırın. Yayınlamadan önce proxy veya güvenli depolama kullanın.
extension AppConfig {
    enum APIConfig {
        static let openAIKey = ""
        static let openAIEndpoint = "https://api.openai.com/v1/chat/completions"
    }
}
