import Foundation

/// Türkiye 2026 bordro mevzuatına uygun PayrollEngine
/// Kümülatif vergi, devreden SGK matrahı ve asgari ücret vergi istisnası dahil
struct BrutNetCalculator {
    
    // MARK: - 2026 Parametreleri
    private static let sgkIsciOrani: Double = 0.14           // %14
    private static let issizlikIsciOrani: Double = 0.01      // %1
    private static let sgkIsverenOrani: Double = 0.155       // %15,5
    private static let issizlikIsverenOrani: Double = 0.02   // %2
    private static let sgkTavani: Double = 297_270           // SGK Tavanı (TL)
    private static let asgariUcretBrut: Double = 33_030      // Brüt asgari ücret (TL)
    private static let damgaVergisiOrani: Double = 0.00759   // %0,759 (asgari ücret kadar istisna)
    
    private static let asgariUcretMatrah: Double = 28_075.50 // 33030 × 0.85
    
    // Gelir vergisi dilimleri 2026 (Yıllık kümülatif matrah - TL)
    private static let gelirVergisiDilimleri: [(ustSinir: Double, oran: Double)] = [
        (190_000, 0.15),
        (400_000, 0.20),
        (1_500_000, 0.27),
        (5_300_000, 0.35),
        (Double.infinity, 0.40)
    ]
    
    /// Devreden SGK matrahı — 2 ay ömürlü
    private struct SGKCarryOver {
        var amount: Double
        var remainingMonths: Int
    }
    
    struct Sonuc {
        let brut: Double
        let prim: Double
        let net: Double
        let kesintiler: [KesintiKalemi]
        let toplamKesinti: Double
    }
    
    /// Yıllık hesaplama — (brut, prim) çiftleri; hesaplaYillikDetayli üzerinden
    static func hesaplaYillik(brutlar: [Double], primler: [Double]? = nil) -> [Sonuc] {
        let detaylar = hesaplaYillikDetayli(brutlar: brutlar, primler: primler)
        return detaylar.map { d in
            let kesintiler = [
                KesintiKalemi(ad: "SGK İşçi Payı", tutar: d.sgkIsci, oran: 14),
                KesintiKalemi(ad: "İşsizlik Sigortası İşçi Payı", tutar: d.issizlikIsci, oran: 1),
                KesintiKalemi(ad: "Gelir Vergisi", tutar: d.aylikGelirVergisi, oran: nil),
                KesintiKalemi(ad: "Damga Vergisi", tutar: d.damgaVergisi, oran: 0.759)
            ]
            let toplamKesinti = d.sgkIsci + d.issizlikIsci + d.aylikGelirVergisi + d.damgaVergisi
            return Sonuc(brut: d.brut, prim: d.prim, net: d.toplamNetEleGecen, kesintiler: kesintiler, toplamKesinti: toplamKesinti)
        }
    }
    
    /// Yıllık detaylı hesaplama (tablo için)
    static func hesaplaYillikDetayli(brutlar: [Double], primler: [Double]? = nil) -> [AylikBrutNetDetay] {
        let primList = primler ?? Array(repeating: 0, count: brutlar.count)
        var detaylar: [AylikBrutNetDetay] = []
        var devreden: [SGKCarryOver] = []
        var oncekiAylarMatrahlari: [Double] = []
        
        for index in 0..<12 {
            let brut = index < brutlar.count ? brutlar[index] : 0
            let prim = index < primList.count ? primList[index] : 0
            let brutArtıPrim = brut + prim
            
            guard brutArtıPrim > 0 else {
                detaylar.append(AylikBrutNetDetay(ay: index + 1, brut: brut, prim: prim, sgkIsci: 0, issizlikIsci: 0, aylikGelirVergisi: 0, damgaVergisi: 0, kumulatifVergiMatrahi: 0, netVergiOncesi: 0, agi: 0, asgariUcretGVIstisnasi: 0, asgariUcretDVIstisnasi: 0, toplamNetEleGecen: 0, sgkIsveren: 0, issizlikIsveren: 0, toplamMaliyet: 0))
                oncekiAylarMatrahlari.append(0)
                continue
            }
            
            let carryToplam = devreden.reduce(0) { $0 + $1.amount }
            let totalPotential = brutArtıPrim + carryToplam
            let appliedMatrah = min(totalPotential, sgkTavani)
            let currentMonthExcess = max(0, brutArtıPrim - sgkTavani)
            
            var yeniListe: [SGKCarryOver] = []
            if currentMonthExcess > 0 {
                yeniListe.append(SGKCarryOver(amount: currentMonthExcess, remainingMonths: 2))
            }
            for item in devreden {
                if item.remainingMonths > 1 {
                    yeniListe.append(SGKCarryOver(amount: item.amount, remainingMonths: item.remainingMonths - 1))
                }
            }
            devreden = yeniListe
            
            let sgkIsci = (appliedMatrah * sgkIsciOrani).yuvarla()
            let issizlikIsci = (appliedMatrah * issizlikIsciOrani).yuvarla()
            let aylikMatrah = (brutArtıPrim - sgkIsci - issizlikIsci).yuvarla()
            
            let kumulatifMatrahOnceki = oncekiAylarMatrahlari.reduce(0, +)
            let kumulatifMatrahBuAy = kumulatifMatrahOnceki + aylikMatrah
            
            let kumulatifVergiOnceki = kumulatifVergiHesapla(matrah: kumulatifMatrahOnceki)
            let kumulatifVergiBuAy = kumulatifVergiHesapla(matrah: kumulatifMatrahBuAy)
            let brutGelirVergisi = (kumulatifVergiBuAy - kumulatifVergiOnceki).yuvarla()
            
            let oncekiAySayisi = oncekiAylarMatrahlari.count
            let kumulatifAsgariMatrahOnceki = Double(oncekiAySayisi) * asgariUcretMatrah
            let kumulatifAsgariMatrahBuAy = Double(oncekiAySayisi + 1) * asgariUcretMatrah
            let asgariVergiOnceki = kumulatifVergiHesapla(matrah: kumulatifAsgariMatrahOnceki)
            let asgariVergiBuAy = kumulatifVergiHesapla(matrah: kumulatifAsgariMatrahBuAy)
            let asgariGVIstisnasi = (asgariVergiBuAy - asgariVergiOnceki).yuvarla()
            let netGelirVergisi = max(0, (brutGelirVergisi - asgariGVIstisnasi).yuvarla())
            
            let damgaMatrah = max(0, brutArtıPrim - asgariUcretBrut)
            let damgaVergisi = (damgaMatrah * damgaVergisiOrani).yuvarla()
            let asgariDVIstisnasi = (asgariUcretBrut * damgaVergisiOrani).yuvarla()
            
            let netVergiOncesi = (brutArtıPrim - sgkIsci - issizlikIsci - brutGelirVergisi - damgaVergisi).yuvarla()
            let toplamNetEleGecen = (netVergiOncesi + asgariGVIstisnasi).yuvarla()
            
            let sgkIsveren = (appliedMatrah * sgkIsverenOrani).yuvarla()
            let issizlikIsveren = (appliedMatrah * issizlikIsverenOrani).yuvarla()
            let toplamMaliyet = (brutArtıPrim + sgkIsveren + issizlikIsveren).yuvarla()
            
            detaylar.append(AylikBrutNetDetay(
                ay: index + 1,
                brut: brut,
                prim: prim,
                sgkIsci: sgkIsci,
                issizlikIsci: issizlikIsci,
                aylikGelirVergisi: netGelirVergisi,
                damgaVergisi: damgaVergisi,
                kumulatifVergiMatrahi: kumulatifMatrahBuAy,
                netVergiOncesi: netVergiOncesi,
                agi: 0,
                asgariUcretGVIstisnasi: asgariGVIstisnasi,
                asgariUcretDVIstisnasi: asgariDVIstisnasi,
                toplamNetEleGecen: toplamNetEleGecen,
                sgkIsveren: sgkIsveren,
                issizlikIsveren: issizlikIsveren,
                toplamMaliyet: toplamMaliyet
            ))
            oncekiAylarMatrahlari.append(aylikMatrah)
        }
        
        return detaylar
    }
    
    private static func kumulatifVergiHesapla(matrah: Double) -> Double {
        guard matrah > 0 else { return 0 }
        var vergi: Double = 0
        var kalanMatrah = matrah
        var oncekiSinir: Double = 0
        for dilim in gelirVergisiDilimleri {
            let dilimGenisligi = dilim.ustSinir - oncekiSinir
            let dilimTutari = min(kalanMatrah, dilimGenisligi)
            if dilimTutari <= 0 { break }
            vergi += dilimTutari * dilim.oran
            kalanMatrah -= dilimTutari
            oncekiSinir = dilim.ustSinir
            if kalanMatrah <= 0 { break }
        }
        return vergi
    }
}

private extension Double {
    func yuvarla() -> Double {
        (self * 100).rounded() / 100
    }
}
