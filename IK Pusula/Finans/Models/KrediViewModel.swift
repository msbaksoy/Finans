import Foundation
import SwiftUI

// MARK: - Kredi Türü
enum HKrediTuru: CaseIterable {
    case tuketici, tasit, konut

    var label: String {
        switch self {
        case .tuketici: return "Tüketici"
        case .tasit:    return "Taşıt"
        case .konut:    return "Konut"
        }
    }

    var icon: String {
        switch self {
        case .tuketici: return "creditcard.fill"
        case .tasit:    return "car.fill"
        case .konut:    return "house.fill"
        }
    }

    var renk: Color {
        switch self {
        case .tuketici: return Color(hex: "8B5CF6")
        case .tasit:    return Color(hex: "F59E0B")
        case .konut:    return Color(hex: "06B6D4")
        }
    }

    var maxVade: Int {
        switch self {
        case .tuketici: return 60
        case .tasit:    return 48
        case .konut:    return 360
        }
    }
}

// MARK: - Hesaplama Sonucu
struct KrediHesapSonucu {
    let aylikTaksit: Double
    let toplamFaiz: Double
    let toplamMaliyet: Double
    let tuketiciPlan: [KrediCalculator.OdemeSatiri]?
    let konutPlan: [KrediCalculator.KonutOdemeSatiri]?
}

// MARK: - ViewModel
@MainActor
final class KrediViewModel: ObservableObject {
    @Published var secilenTur: HKrediTuru = .tuketici
    @Published var anaparaText = ""
    @Published var vadeText = ""
    @Published var faizText = ""
    @Published var sonuc: KrediHesapSonucu?
    @Published var odemeGoster = false
    @Published var isRefreshing = false

    /// Hesaplama orkestrasyonu; config tüketici/taşıt için KKDF/BSMV oranlarını sağlar.
    func hesapla(krediConfig: KrediConfigService) {
        guard
            let anapara = parseFormattedNumber(anaparaText),
            let vadeVal = parseFormattedNumber(vadeText),
            let faiz = parseFormattedNumber(faizText),
            anapara > 0, faiz >= 0
        else { sonuc = nil; return }

        let vade = Int(vadeVal)
        guard vade >= 1, vade <= secilenTur.maxVade else { sonuc = nil; return }

        odemeGoster = false

        switch secilenTur {
        case .tuketici, .tasit:
            let c = krediConfig.config
            let plan = KrediCalculator.tuketiciKredisiHesapla(
                anapara: anapara, vade: vade, aylikFaizOrani: faiz,
                kkdfOrani: c.kkdfOrani, bsmvOrani: c.bsmvOrani
            )
            sonuc = KrediHesapSonucu(
                aylikTaksit: plan.first?.taksitTutari ?? 0,
                toplamFaiz: plan.reduce(0) { $0 + $1.faiz },
                toplamMaliyet: plan.reduce(0) { $0 + $1.taksitTutari },
                tuketiciPlan: plan,
                konutPlan: nil
            )

        case .konut:
            let plan = KrediCalculator.konutKredisiHesapla(
                anapara: anapara, vade: vade, aylikFaizOrani: faiz
            )
            sonuc = KrediHesapSonucu(
                aylikTaksit: plan.first?.taksitTutari ?? 0,
                toplamFaiz: plan.reduce(0) { $0 + $1.faiz },
                toplamMaliyet: plan.reduce(0) { $0 + $1.taksitTutari },
                tuketiciPlan: nil,
                konutPlan: plan
            )
        }
    }

    func turSecildi(_ tur: HKrediTuru) {
        secilenTur = tur
        sonuc = nil
        odemeGoster = false
    }
}
