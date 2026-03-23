import Foundation

/// Türkiye 2026 bordro — parçalı dilim hesaplaması, SGK matrah devri ve %40 vergi dilimi kurallarına tam uyumlu hesaplama motoru.
struct BrutNetCalculator {

    // MARK: - 2026 Kesinleşmiş / Hedeflenen Parametreler
    static let sgkTavani: Double = 297_270.00
    static let asgariBrut: Double = 33_030.00
    static let damgaOrani: Double = 0.00759

    // MARK: - Yasal Kesinti Oranları
    static let sgkIsciOrani: Double = 0.14         // %14
    static let issizlikIsciOrani: Double = 0.01    // %1
    static let sgkIsverenOrani: Double = 0.155     // %15.5 (5510 sayılı %5 indirim uygulanmış)
    static let issizlikIsverenOrani: Double = 0.02 // %2

    // Sınırlar: 190.000, 400.000, 1.500.000, 5.000.000
    static let dilimler: [(sinir: Double, oran: Double)] = [
        (190_000, 0.15),
        (400_000, 0.20),
        (1_500_000, 0.27),
        (5_000_000, 0.35)
    ]
    private static let ustDilimOrani: Double = 0.40

    // MARK: - Tek Ay Hesaplama
    static func hesapla(brut: Double, kumulatifMatrah: Double, asgariKumulatif: Double = 0) -> MaasSonuc {
        // 1. SGK İşçi Payları
        let sgkEsasKazanc = min(brut, sgkTavani)
        let sgkIsci = (sgkEsasKazanc * sgkIsciOrani).yuvarla()
        let issizlikIsci = (sgkEsasKazanc * issizlikIsciOrani).yuvarla()
        let toplamSgkIsci = sgkIsci + issizlikIsci

        // 2. Gelir Vergisi
        let gvMatrah = (brut - toplamSgkIsci).yuvarla()
        let hamGelirVergisi = dilimliHesapla(matrah: gvMatrah, baslangicKumulatif: kumulatifMatrah)

        // 3. Asgari Ücret İstisnası
        let asgariSgkIsci = (asgariBrut * sgkIsciOrani).yuvarla()
        let asgariIssizlikIsci = (asgariBrut * issizlikIsciOrani).yuvarla()
        let asgariGvMatrah = (asgariBrut - asgariSgkIsci - asgariIssizlikIsci).yuvarla()
        let gvIstisnasi = dilimliHesapla(matrah: asgariGvMatrah, baslangicKumulatif: asgariKumulatif)
        let dvIstisnasi = (asgariBrut * damgaOrani).yuvarla()

        // 4. Uygulanan İstisna Kontrolü (Vergi borcunu aşamaz)
        let uygulananGvIstisnasi = min(hamGelirVergisi, gvIstisnasi)
        let hamDamgaVergisi = (brut * damgaOrani).yuvarla()
        let uygulananDvIstisnasi = min(hamDamgaVergisi, dvIstisnasi)

        let odenecekGv = (hamGelirVergisi - uygulananGvIstisnasi).yuvarla()
        let odenecekDv = (hamDamgaVergisi - uygulananDvIstisnasi).yuvarla()

        let netMaas = (brut - toplamSgkIsci - odenecekGv - odenecekDv).yuvarla()

        // İşveren SGK %15.5 + İşsizlik %2 = toplam %17.5 (önceki hatalı 0.175+0.02 düzeltildi)
        let sgkIsveren = (sgkEsasKazanc * sgkIsverenOrani).yuvarla()
        let issizlikIsveren = (sgkEsasKazanc * issizlikIsverenOrani).yuvarla()

        return MaasSonuc(
            net: netMaas,
            vergi: odenecekGv,
            sgk: toplamSgkIsci,
            damga: odenecekDv,
            avantaj: (uygulananGvIstisnasi + uygulananDvIstisnasi).yuvarla(),
            maliyet: (brut + sgkIsveren + issizlikIsveren).yuvarla()
        )
    }

    /// Parçalı fonksiyon: Kümülatif matrah dilim sınırını geçtiği an (örn. 400k) otomatik %27 dilimine geçiş.
    static func dilimliHesapla(matrah: Double, baslangicKumulatif: Double) -> Double {
        var vergi = 0.0
        var islenecekMatrah = matrah
        var guncelKumulatif = baslangicKumulatif

        for dilim in dilimler {
            if guncelKumulatif < dilim.sinir {
                let bosluk = dilim.sinir - guncelKumulatif
                let buDilimdeIslenecek = min(islenecekMatrah, bosluk)
                vergi += buDilimdeIslenecek * dilim.oran
                islenecekMatrah -= buDilimdeIslenecek
                guncelKumulatif += buDilimdeIslenecek
            }
            if islenecekMatrah <= 0 { break }
        }
        // 5.000.000 TL üzerindeki matrah en üst dilim olan %40 ile vergilendirilir
        if islenecekMatrah > 0 {
            vergi += islenecekMatrah * ustDilimOrani
        }
        return vergi.yuvarla()
    }

    struct Sonuc {
        let brut: Double
        let prim: Double
        let net: Double
        let kesintiler: [KesintiKalemi]
        let toplamKesinti: Double
    }

    static func hesaplaYillik(brutlar: [Double], primler: [Double]? = nil) -> [Sonuc] {
        let detaylar = hesaplaYillikDetayli(brutlar: brutlar, primler: primler)
        return detaylar.map { d in
            let kesintiler = [
                KesintiKalemi(ad: "SGK İşçi Payı", tutar: d.sgkIsci, oran: sgkIsciOrani * 100),
                KesintiKalemi(ad: "İşsizlik İşçi Payı", tutar: d.issizlikIsci, oran: issizlikIsciOrani * 100),
                KesintiKalemi(ad: "Gelir Vergisi", tutar: d.aylikGelirVergisi, oran: nil),
                KesintiKalemi(ad: "Damga Vergisi", tutar: d.damgaVergisi, oran: damgaOrani * 100)
            ]
            let toplamKesinti = d.sgkIsci + d.issizlikIsci + d.aylikGelirVergisi + d.damgaVergisi
            return Sonuc(brut: d.brut, prim: d.prim, net: d.toplamNetEleGecen, kesintiler: kesintiler, toplamKesinti: toplamKesinti)
        }
    }

    /// 5510 sayılı Kanun Madde 80/c gereği: Bir ayda tavan aşan prim, izleyen iki ay içinde
    /// SGK matrahına eklenir. Kuyruk yapısıyla maksimum 2 ay boyunca devir takibi yapılır.
    static func hesaplaYillikDetayli(brutlar: [Double], primler: [Double]? = nil) -> [AylikBrutNetDetay] {
        let primList = primler ?? Array(repeating: 0.0, count: 12)
        var detaylar: [AylikBrutNetDetay] = []
        var kumulatif: Double = 0
        var asgariKumulatif: Double = 0

        // Asgari ücret istisnası matrahı tüm yıl sabit olduğundan döngü dışında hesaplanır
        let asgariSgkIsciSabit = (asgariBrut * sgkIsciOrani).yuvarla()
        let asgariIssizlikIsciSabit = (asgariBrut * issizlikIsciOrani).yuvarla()
        let asgariGvMatrah = (asgariBrut - asgariSgkIsciSabit - asgariIssizlikIsciSabit).yuvarla()

        // SGK prim devri kuyruğu: [1. sonraki aya devir, 2. sonraki aya devir]
        var sgkDevir: [Double] = [0.0, 0.0]

        for index in 0..<12 {
            let brut = index < brutlar.count ? brutlar[index] : 0
            let prim = index < primList.count ? primList[index] : 0
            let toplamBrut = brut + prim

            // Bu aya ait SGK devir tutarını kuyruğun başından al
            let buAyDevreden = sgkDevir.removeFirst()
            sgkDevir.append(0.0)

            // SGK matrahı: brüt + devreden prim, tavana kadar
            let sgkMatrahi = toplamBrut + buAyDevreden
            let sgkEsasKazanc = min(sgkMatrahi, sgkTavani)

            // Tavan aşımı varsa, sadece prim kaynaklı aşım devredebilir
            let asanKisim = max(0, sgkMatrahi - sgkTavani)
            let devredilebilir = min(asanKisim, prim + buAyDevreden)
            if devredilebilir > 0 {
                // Aşan tutarı sonraki aya yükle (2 aylık kuyruğun ilk boşluğu)
                sgkDevir[0] = (sgkDevir[0] + devredilebilir).yuvarla()
            }

            let sgkIsci = (sgkEsasKazanc * sgkIsciOrani).yuvarla()
            let issizlikIsci = (sgkEsasKazanc * issizlikIsciOrani).yuvarla()
            let toplamSgkIsci = sgkIsci + issizlikIsci

            // GV matrahı gerçek brüt üzerinden hesaplanır (SGK devrinden bağımsız)
            let gvMatrahBuAy = (toplamBrut - toplamSgkIsci).yuvarla()
            let hamGelirVergisi = dilimliHesapla(matrah: gvMatrahBuAy, baslangicKumulatif: kumulatif)

            // Asgari ücret istisnası (asgariGvMatrah döngü dışında sabit hesaplandı)
            let gvIstisnasi = dilimliHesapla(matrah: asgariGvMatrah, baslangicKumulatif: asgariKumulatif)
            let dvIstisnasi = (asgariBrut * damgaOrani).yuvarla()

            let uygulananGvIstisnasi = min(hamGelirVergisi, gvIstisnasi)
            let hamDamgaVergisi = (toplamBrut * damgaOrani).yuvarla()
            let uygulananDvIstisnasi = min(hamDamgaVergisi, dvIstisnasi)

            let odenecekGv = (hamGelirVergisi - uygulananGvIstisnasi).yuvarla()
            let odenecekDv = (hamDamgaVergisi - uygulananDvIstisnasi).yuvarla()

            let netMaas = (toplamBrut - toplamSgkIsci - odenecekGv - odenecekDv).yuvarla()
            let sgkIsveren = (sgkEsasKazanc * sgkIsverenOrani).yuvarla()
            let issizlikIsveren = (sgkEsasKazanc * issizlikIsverenOrani).yuvarla()

            detaylar.append(AylikBrutNetDetay(
                ay: index + 1, brut: brut, prim: prim,
                sgkIsci: sgkIsci,
                issizlikIsci: issizlikIsci,
                aylikGelirVergisi: odenecekGv,
                damgaVergisi: odenecekDv,
                kumulatifVergiMatrahi: kumulatif + gvMatrahBuAy,
                netVergiOncesi: gvMatrahBuAy,
                agi: 0,
                asgariUcretGVIstisnasi: uygulananGvIstisnasi,
                asgariUcretDVIstisnasi: uygulananDvIstisnasi,
                toplamNetEleGecen: netMaas,
                sgkIsveren: sgkIsveren,
                issizlikIsveren: issizlikIsveren,
                toplamMaliyet: (toplamBrut + sgkIsveren + issizlikIsveren).yuvarla()
            ))

            kumulatif += gvMatrahBuAy
            asgariKumulatif += asgariGvMatrah
        }
        return detaylar
    }
}

extension Double {
    func yuvarla() -> Double {
        (self * 100).rounded() / 100
    }
}
