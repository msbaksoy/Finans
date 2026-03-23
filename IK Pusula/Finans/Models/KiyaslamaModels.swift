import Foundation

/// Ulaşım türü (şirket aracı / servis / toplu taşıma) — Kıyaslama yol süresi adımında kullanılır.
enum TransportMethod: String, CaseIterable {
    case companyVehicle = "Şirket Aracı"
    case shuttle = "Servis"
    case publicTransport = "Toplu Taşıma"
    var icon: String {
        switch self {
        case .companyVehicle: return "car.fill"
        case .shuttle: return "bus"
        case .publicTransport: return "tram.fill"
        }
    }
    var displayName: String { rawValue }
}

/// Çalışma modeli (ofis / remote / hibrit) — Kıyaslama akışında kullanılır.
enum WorkModel: String, CaseIterable {
    case remote = "Remote"
    case office = "Ofis"
    case hybrid = "Hibrit"

    var icon: String {
        switch self {
        case .remote: return "house"
        case .office: return "building.2"
        case .hybrid: return "laptopcomputer"
        }
    }

    var displayName: String { rawValue }
}

/// Yemek imkanı alternatifleri (yemekhane / kart / yok).
enum YemekImkani: String, CaseIterable {
    case yemekhane = "Yemekhane"
    case yemekKarti = "Yemek Kartı"
    case yok = "Yok"

    var icon: String {
        switch self {
        case .yemekhane: return "fork.knife"
        case .yemekKarti: return "creditcard.fill"
        case .yok: return "xmark.circle"
        }
    }
}

/// Kıyaslama akışında her iki iş yeri için toplanan yan hak bilgisi.
struct YanHaklar {
    var tamamlayiciSS: Bool = false
    var tamamlayiciSSAile: Bool = false
    var ozelSS: Bool = false
    var ozelSSAile: Bool = false
    var bes: Bool = false
    var besAylikKatki: Double = 0

    static let bos = YanHaklar()
}

/// Kıdem grubu (unvan analizi için — rank 1–5).
enum KademGrubu: String, CaseIterable {
    case junior = "Junior"
    case professional = "Professional"
    case senior = "Senior"
    case manager = "Manager"
    case executive = "Executive"

    var rank: Int {
        switch self {
        case .junior: return 1
        case .professional: return 2
        case .senior: return 3
        case .manager: return 4
        case .executive: return 5
        }
    }

    var displayName: String { rawValue }
}

/// Unvan ve bağlı olduğu kıdem grubu.
struct UnvanItem: Identifiable {
    let id: String
    let ad: String
    let kademGrubu: KademGrubu

    var rank: Int { kademGrubu.rank }
}

/// Kıyaslama akışında kullanılan unvan listesi (kurumsal + bankacılık).
let unvanListesi: [UnvanItem] = [
    // Junior (1) — Kurumsal
    UnvanItem(id: "asistan", ad: "Asistan / Aday", kademGrubu: .junior),
    UnvanItem(id: "uzman-yard", ad: "Uzman Yardımcısı", kademGrubu: .junior),
    // Professional (2)
    UnvanItem(id: "uzman", ad: "Uzman", kademGrubu: .professional),
    UnvanItem(id: "kıdemli-uzman", ad: "Kıdemli Uzman", kademGrubu: .senior),
    UnvanItem(id: "bas-uzman", ad: "Baş Uzman / Uzman Müşavir", kademGrubu: .senior),
    UnvanItem(id: "mudur-yard", ad: "Müdür Yardımcısı", kademGrubu: .manager),
    UnvanItem(id: "mudur", ad: "Müdür", kademGrubu: .manager),
    UnvanItem(id: "grup-mudur", ad: "Grup Müdürü / Kıdemli Müdür", kademGrubu: .manager),
    UnvanItem(id: "direktor", ad: "Direktör", kademGrubu: .executive),
    UnvanItem(id: "bolum-baskan", ad: "Bölüm Başkanı / Koordinatör", kademGrubu: .executive),
    UnvanItem(id: "gmy", ad: "Genel Müdür Yardımcısı", kademGrubu: .executive),
    UnvanItem(id: "gm-ceo", ad: "Genel Müdür / CEO", kademGrubu: .executive),
    // Bankacılık
    UnvanItem(id: "mufettis", ad: "Müfettiş / Uzman Yardımcısı", kademGrubu: .junior),
    UnvanItem(id: "yetkili-yard", ad: "Yetkili Yardımcısı", kademGrubu: .professional),
    UnvanItem(id: "yetkili", ad: "Yetkili", kademGrubu: .professional),
    UnvanItem(id: "kıdemli-yetkili", ad: "Kıdemli Yetkili", kademGrubu: .senior),
    UnvanItem(id: "yonetmen-yard", ad: "Yönetmen Yardımcısı", kademGrubu: .manager),
    UnvanItem(id: "yonetmen", ad: "Yönetmen", kademGrubu: .manager),
    UnvanItem(id: "birim-mudur", ad: "Birim Müdürü", kademGrubu: .executive),
]

// MARK: - Grade ve Unvan Yönetimi (Rank 1–5)

struct KariyerUnvan: Identifiable, Hashable {
    let id = UUID()
    let ad: String
    let rank: Int       // 1-5 arası derece
    let kategori: String
}

enum KariyerGradeManager {
    static let unvanlar: [KariyerUnvan] = [
        // Rank 1 - Giriş (Entry)
        KariyerUnvan(ad: "Uzman Yardımcısı", rank: 1, kategori: "Giriş"),
        KariyerUnvan(ad: "Müfettiş Yardımcısı", rank: 1, kategori: "Giriş"),
        KariyerUnvan(ad: "Asistan", rank: 1, kategori: "Giriş"),
        KariyerUnvan(ad: "Yetkili Yardımcısı", rank: 1, kategori: "Giriş"),
        KariyerUnvan(ad: "Aday", rank: 1, kategori: "Giriş"),
        KariyerUnvan(ad: "Stajyer", rank: 1, kategori: "Giriş"),

        // Rank 2 - Orta (Mid-Level)
        KariyerUnvan(ad: "Uzman", rank: 2, kategori: "Orta"),
        KariyerUnvan(ad: "Yetkili", rank: 2, kategori: "Orta"),
        KariyerUnvan(ad: "Analist", rank: 2, kategori: "Orta"),
        KariyerUnvan(ad: "Denetçi", rank: 2, kategori: "Orta"),
        KariyerUnvan(ad: "Müfettiş", rank: 2, kategori: "Orta"),
        KariyerUnvan(ad: "Müşteri Temsilcisi", rank: 2, kategori: "Orta"),

        // Rank 3 - Kıdemli (Senior/Lead)
        KariyerUnvan(ad: "Kıdemli Uzman", rank: 3, kategori: "Kıdemli"),
        KariyerUnvan(ad: "Kıdemli Yetkili", rank: 3, kategori: "Kıdemli"),
        KariyerUnvan(ad: "Baş Uzman", rank: 3, kategori: "Kıdemli"),
        KariyerUnvan(ad: "Kıdemli Analist", rank: 3, kategori: "Kıdemli"),
        KariyerUnvan(ad: "Takım Lideri", rank: 3, kategori: "Kıdemli"),

        // Rank 4 - Yönetimsel (Management)
        KariyerUnvan(ad: "Müdür Yardımcısı", rank: 4, kategori: "Yönetimsel"),
        KariyerUnvan(ad: "Yönetmen", rank: 4, kategori: "Yönetimsel"),
        KariyerUnvan(ad: "Yönetici Yardımcısı", rank: 4, kategori: "Yönetimsel"),
        KariyerUnvan(ad: "Birim Müdürü", rank: 4, kategori: "Yönetimsel"),
        KariyerUnvan(ad: "Şef", rank: 4, kategori: "Yönetimsel"),
        KariyerUnvan(ad: "Müdür", rank: 4, kategori: "Yönetimsel"),

        // Rank 5 - Üst Yönetim (Executive)
        KariyerUnvan(ad: "Direktör", rank: 5, kategori: "Üst Yönetim"),
        KariyerUnvan(ad: "Bölüm Başkanı", rank: 5, kategori: "Üst Yönetim"),
        KariyerUnvan(ad: "Genel Müdür Yardımcısı (GMY)", rank: 5, kategori: "Üst Yönetim"),
        KariyerUnvan(ad: "CEO", rank: 5, kategori: "Üst Yönetim"),
        KariyerUnvan(ad: "CTO", rank: 5, kategori: "Üst Yönetim"),
        KariyerUnvan(ad: "CFO", rank: 5, kategori: "Üst Yönetim"),
        KariyerUnvan(ad: "COO", rank: 5, kategori: "Üst Yönetim"),
    ]
}

