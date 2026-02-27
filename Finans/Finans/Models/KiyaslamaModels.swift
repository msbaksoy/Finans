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

