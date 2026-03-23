import Foundation

/// Fakülte adları için arama servisi. Kelime başı büyük, "Diğer" seçeneği var.
struct FakulteDataService {
    private static let tr = Locale(identifier: "tr_TR")

    private static let hamListe: [String] = [
        "Açıköğretim Fakültesi",
        "Arkeoloji Fakültesi",
        "Atatürk Eğitim Fakültesi",
        "Bankacılık ve Sigortacılık Fakültesi",
        "Bilgisayar ve Bilişim Bilimleri Fakültesi",
        "Bilgi Teknolojileri Fakültesi",
        "Bilişim Sistemleri Fakültesi",
        "Biyoloji Fakültesi",
        "Biyoteknolojik Bilimler Fakültesi",
        "Çalışma Ekonomisi Fakültesi",
        "Denizcilik Fakültesi",
        "Dil ve Tarih-Coğrafya Fakültesi",
        "Diş Hekimliği Fakültesi",
        "Eczacılık Fakültesi",
        "Edebiyat Fakültesi",
        "Eğitim Bilimleri Fakültesi",
        "Eğitim Fakültesi",
        "Elektrik ve Elektronik Fakültesi",
        "Enerji Sistemleri Fakültesi",
        "Endüstri Mühendisliği Fakültesi",
        "Fen Edebiyat Fakültesi",
        "Fen Fakültesi",
        "Felsefe Fakültesi",
        "Fizik Tedavi ve Rehabilitasyon Fakültesi",
        "Genetik ve Biyoengineering Fakültesi",
        "Gemi İnşaatı ve Deniz Bilimleri Fakültesi",
        "Gıda Bilimleri Fakültesi",
        "Görsel İletişim Tasarımı Fakültesi",
        "Güzel Sanatlar Fakültesi",
        "Güzel Sanatlar, Tasarım ve Mimarlık Fakültesi",
        "Hasan Âli Yücel Eğitim Fakültesi",
        "Havacılık Fakültesi",
        "Havacılık ve Astronomi Fakültesi",
        "Havacılık ve Uzay Bilimleri Fakültesi",
        "Hemşirelik Fakültesi",
        "Hukuk Fakültesi",
        "Hukuk ve Sosyal Bilimler Fakültesi",
        "İç Mimarlık ve Çevre Tasarımı Fakültesi",
        "İktisadi ve İdari Bilimler Fakültesi",
        "İktisadi, İdari ve Sosyal Bilimler Fakültesi",
        "İktisat Fakültesi",
        "İlahiyat Fakültesi",
        "İletişim Bilimleri Fakültesi",
        "İletişim Fakültesi",
        "İnsani ve Sosyal Bilimler Fakültesi",
        "İnsan ve Toplum Bilimleri Fakültesi",
        "İnşaat Fakültesi",
        "İslami İlimler Fakültesi",
        "İşletme Fakültesi",
        "İşletme ve Yönetim Bilimleri Fakültesi",
        "İstatistik Fakültesi",
        "Jeoloji Mühendisliği Fakültesi",
        "Kamu Yönetimi Fakültesi",
        "Kimya Fakültesi",
        "Kültür ve Sosyal Bilimler Fakültesi",
        "Lojistik Fakültesi",
        "Makine Fakültesi",
        "Maden Fakültesi",
        "Maliye Fakültesi",
        "Matematik Fakültesi",
        "Medya ve İletişim Fakültesi",
        "Mimarlık Fakültesi",
        "Mimarlık ve Tasarım Fakültesi",
        "Mimarlık, Tasarım ve Güzel Sanatlar Fakültesi",
        "Mühendislik Fakültesi",
        "Mühendislik ve Doğa Bilimleri Fakültesi",
        "Mühendislik ve Mimarlık Fakültesi",
        "Müzik ve Sahne Sanatları Fakültesi",
        "Orman Fakültesi",
        "Psikoloji Fakültesi",
        "Radyo, Televizyon ve Sinema Fakültesi",
        "Sağlık Bilimleri Fakültesi",
        "Sağlık Yönetimi Fakültesi",
        "Sanat Tarihi Fakültesi",
        "Sanat ve Tasarım Fakültesi",
        "Sanat, Tasarım ve Mimarlık Fakültesi",
        "Siyasal Bilgiler Fakültesi",
        "Sivil Havacılık Fakültesi",
        "Sosyal ve Beşeri Bilimler Fakültesi",
        "Sosyoloji Fakültesi",
        "Spor Bilimleri Fakültesi",
        "Su Ürünleri Fakültesi",
        "Tarım ve Doğa Bilimleri Fakültesi",
        "Tarih Fakültesi",
        "Tasarım ve Güzel Sanatlar Fakültesi",
        "Teknoloji Fakültesi",
        "Tıp Fakültesi",
        "Tiyatro ve Sahne Sanatları Fakültesi",
        "Turizm Fakültesi",
        "Ulaştırma ve Lojistik Fakültesi",
        "Uluslararası İlişkiler Fakültesi",
        "Uluslararası Ticaret Fakültesi",
        "Uygulamalı Bilimler Fakültesi",
        "Veteriner Fakültesi",
        "Yabancı Diller Fakültesi",
        "Yazılım Mühendisliği Fakültesi",
        "Ziraat Fakültesi",
        "Ziraat ve Doğa Bilimleri Fakültesi",
        "Şehir ve Bölge Planlama Fakültesi",
        "Diğer"
    ]

    static var fakulteler: [String] {
        hamListe.sorted { $0.localizedCompare($1) == .orderedAscending }
    }

    static func searchFakulteler(query: String, limit: Int = 12) -> [String] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return [] }

        let lowerQuery = trimmed.lowercased(with: tr)
        let list = fakulteler

        let filtered = list.filter { name in
            name.lowercased(with: tr).contains(lowerQuery)
        }

        return Array(filtered.prefix(limit))
    }
}
