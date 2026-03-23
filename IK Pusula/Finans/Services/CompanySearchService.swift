import Foundation
import Combine

// MARK: - Şirket Modeli (Clearbit Autocomplete)
struct CompanySuggestion: Codable, Identifiable, Equatable {
    let name: String
    let domain: String
    let logo: String?

    var id: String { domain }
    /// API bazen logo döndürmüyor; domain ile Clearbit Logo API kullanıyoruz
    var logoURL: URL? {
        if let logo = logo, !logo.isEmpty, let url = URL(string: logo) { return url }
        let fallback = "https://logo.clearbit.com/\(domain)"
        return URL(string: fallback)
    }
}

// MARK: - Arama Servisi (Debounce + Türkçe yerel zeka + VIP liste)
final class CompanySearchService: ObservableObject {
    @Published var searchQuery = ""
    @Published var suggestions: [CompanySuggestion] = []
    @Published var isLoading = false

    private var cancellables = Set<AnyCancellable>()

    /// API'nin bulamadığı büyük Türkiye kurumları — doğru domain ile önce listelenir, şelale logoyu çeker
    private let vipCompanies: [CompanySuggestion] = [
        CompanySuggestion(name: "Türkiye Finans Katılım Bankası", domain: "turkiyefinans.com.tr", logo: nil),
        CompanySuggestion(name: "Ziraat Bankası", domain: "ziraatbank.com.tr", logo: nil),
        CompanySuggestion(name: "Kuveyt Türk", domain: "kuveytturk.com.tr", logo: nil),
        CompanySuggestion(name: "VakıfBank", domain: "vakifbank.com.tr", logo: nil),
        CompanySuggestion(name: "Halkbank", domain: "halkbank.com.tr", logo: nil),
    ]

    init() {
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.fetchCompanies(query: query)
            }
            .store(in: &cancellables)
    }

    private func fetchCompanies(query: String) {
        let cleanedQuery = cleanQuery(query)
        guard cleanedQuery.count >= 3 else {
            DispatchQueue.main.async { [weak self] in
                self?.suggestions = []
            }
            return
        }

        isLoading = true

        // VIP listesinden eşleşenleri bul (API'ye gitmeden önce)
        var localMatches: [CompanySuggestion] = []
        for vip in vipCompanies {
            let cleanVipName = cleanQuery(vip.name)
            if cleanVipName.contains(cleanedQuery) || cleanedQuery.contains(cleanVipName) {
                localMatches.append(vip)
            }
        }

        let encoded = cleanedQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? cleanedQuery
        let urlString = "https://autocomplete.clearbit.com/v1/companies/suggest?query=\(encoded)"
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async { [weak self] in
                self?.isLoading = false
                self?.suggestions = localMatches
            }
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                var finalSuggestions = localMatches

                guard let data = data, error == nil,
                      let decoded = try? JSONDecoder().decode([CompanySuggestion].self, from: data) else {
                    self?.suggestions = finalSuggestions
                    return
                }

                let junkWords = ["altyazi", "film", "dizi", "haber", "sozluk", "sözlük", "blog", "oyun", "izle", "indir", "magazin"]
                let filtered = decoded.filter { item in
                    let lowerName = item.name.lowercased()
                    let lowerDomain = item.domain.lowercased()
                    for junk in junkWords {
                        if lowerName.contains(junk) || lowerDomain.contains(junk) { return false }
                    }
                    if localMatches.contains(where: { $0.domain == item.domain }) { return false }
                    return true
                }
                let sortedApi = filtered.sorted { a, b in
                    let aIsTR = a.domain.hasSuffix(".tr") || a.domain.hasSuffix(".com.tr")
                    let bIsTR = b.domain.hasSuffix(".tr") || b.domain.hasSuffix(".com.tr")
                    if aIsTR && !bIsTR { return true }
                    if !aIsTR && bIsTR { return false }
                    return a.name.count < b.name.count
                }
                finalSuggestions.append(contentsOf: sortedApi)
                self?.suggestions = finalSuggestions
            }
        }.resume()
    }

    /// Türkçe karakterleri ASCII'ye çevirir, sonra stop-word temizler (Türkiye Finans Katılım Bankası → turkiye finans)
    private func cleanQuery(_ query: String) -> String {
        var q = query.lowercased()

        // ADIM 1: Türkçe karakterleri İngilizce karşılıklarına çevir (Clearbit API uyumu)
        let turkishChars = ["ç": "c", "ğ": "g", "ı": "i", "ö": "o", "ş": "s", "ü": "u"]
        for (turk, eng) in turkishChars {
            q = q.replacingOccurrences(of: turk, with: eng)
        }

        // ADIM 2: Resmi evrak takıları ve fazlalık kelimeleri sil (artık ASCII)
        let stopWords = [
            " bankasi", " bank", " katilim",
            " a.s.", " a.s", " as", " anonim", " sirketi",
            " ltd", " sti", " sanayi", " ticaret",
            " holding", " grubu", " vakfi"
        ]
        for word in stopWords {
            q = q.replacingOccurrences(of: word, with: "")
        }

        return q.trimmingCharacters(in: .whitespaces)
    }
}
