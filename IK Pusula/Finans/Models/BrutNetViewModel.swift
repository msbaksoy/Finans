import SwiftUI
import SwiftData

/// Maaş hesaplama ekranının mantığı — View sadece UI, hesaplama ve kayıt burada.
@MainActor
final class BrutNetViewModel: ObservableObject {
    @Published var brutlar: [String] = Array(repeating: "", count: 12)
    @Published var primler: [String] = Array(repeating: "", count: 12)
    @Published var donutSecilen: String = "net"

    /// Formdan canlı hesaplama (girilen brüt/prim ile).
    var liveDetayliSonuclar: [AylikBrutNetDetay] {
        let b = (0..<12).map { parseFormattedNumber(brutlar[$0]) ?? 0 }
        let p = (0..<12).map { parseFormattedNumber(primler[$0]) ?? 0 }
        return BrutNetCalculator.hesaplaYillikDetayli(brutlar: b, primler: p)
    }

    /// Canlı detaydan toplam net.
    var toplamNetGosterilen: Double {
        liveDetayliSonuclar.reduce(0) { $0 + $1.toplamNetEleGecen }
    }

    /// Formda en az bir brüt > 0 var mı?
    var hasValidInput: Bool {
        (0..<12).contains { (parseFormattedNumber(brutlar[$0]) ?? 0) > 0 }
    }

    /// Girilen veriyi veritabanına kaydeder; mevcut kayıt varsa günceller.
    func saveToDatabase(context: ModelContext, yil: Int) {
        let brutListesi = (0..<12).map { parseFormattedNumber(brutlar[$0]) ?? 0 }
        let primListesi = (0..<12).map { parseFormattedNumber(primler[$0]) ?? 0 }
        guard brutListesi.contains(where: { $0 > 0 }) else { return }

        let sonuclar = BrutNetCalculator.hesaplaYillik(brutlar: brutListesi, primler: primListesi)
        var descriptor = FetchDescriptor<AylikMaas>(predicate: #Predicate<AylikMaas> { $0.yil == yil })
        descriptor.sortBy = [SortDescriptor(\.ay)]
        let existingList = (try? context.fetch(descriptor)) ?? []

        for (index, sonuc) in sonuclar.enumerated() {
            let ay = index + 1
            let brut = brutListesi[index]
            let prim = primListesi[index]
            let kesintiCodable = sonuc.kesintiler.map { KesintiKalemCodable(ad: $0.ad, tutar: $0.tutar, oran: $0.oran) }
            let maas = AylikMaas(ay: ay, brutTutar: brut, primTutar: prim, netTutar: sonuc.net, kesintiler: kesintiCodable, yil: yil)

            if let existing = existingList.first(where: { $0.ay == ay }) {
                existing.brutTutar = maas.brutTutar
                existing.primTutar = maas.primTutar
                existing.netTutar = maas.netTutar
                existing.kesintiler = maas.kesintiler
            } else {
                context.insert(maas)
            }
        }
        try? context.save()
        HapticHelper.triggerSuccess()
    }
}
