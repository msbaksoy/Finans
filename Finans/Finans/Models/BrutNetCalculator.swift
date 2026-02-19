import Foundation

/// Türkiye brüt maaştan net maaş hesaplama - 2026 parametreleri
/// Kümülatif gelir vergisi matrahı ve asgari ücret vergi istisnası dahil
struct BrutNetCalculator {
    
    // MARK: - 2026 Parametreleri
    private static let sgkIsciOrani: Double = 0.14           // %14
    private static let issizlikIsciOrani: Double = 0.01      // %1
    private static let sgkIsverenOrani: Double = 0.155       // %15,5
    private static let issizlikIsverenOrani: Double = 0.02   // %2
    private static let sgkTavani: Double = 297_270           // Aylık SGK tavanı (TL)
    private static let asgariUcretBrut: Double = 33_030      // Brüt asgari ücret (TL)
    private static let damgaVergisiOrani: Double = 0.00759   // %0,759
    
    // Asgari ücret matrahı: 33030 - (33030×0.14) - (33030×0.01) = 33030 × 0.85 = 28.075,50
    private static let asgariUcretMatrah: Double = 28_075.50
    
    // Gelir vergisi dilimleri 2026 (Yıllık kümülatif matrah - TL)
    private static let gelirVergisiDilimleri: [(ustSinir: Double, oran: Double)] = [
        (190_000, 0.15),
        (400_000, 0.20),
        (1_500_000, 0.27),
        (5_300_000, 0.35),
        (Double.infinity, 0.40)
    ]
    
    struct Sonuc {
        let brut: Double
        let net: Double
        let kesintiler: [KesintiKalemi]
        let toplamKesinti: Double
    }
    
    /// Tek bir ay için hesaplama. Önceki ayların brüt maaşları kümülatif matrah için gerekli.
    /// - Parameters:
    ///   - brut: Bu ayki brüt maaş
    ///   - ay: Ay (1-12)
    ///   - oncekiAylarBrutlari: 1. aydan (ay-1)'e kadar olan brüt maaşlar [Ocak, Şubat, ...]
    static func hesapla(brut: Double, ay: Int = 1, oncekiAylarBrutlari: [Double] = []) -> Sonuc {
        guard brut > 0 else {
            return Sonuc(brut: 0, net: 0, kesintiler: [], toplamKesinti: 0)
        }
        
        var kesintiler: [KesintiKalemi] = []
        
        // Adım 1: SGK kesintileri (tavan uygulanır)
        let sgkBase = min(brut, sgkTavani)
        let sgkIsci = (sgkBase * sgkIsciOrani).yuvarla()
        let issizlikIsci = (sgkBase * issizlikIsciOrani).yuvarla()
        
        kesintiler.append(KesintiKalemi(ad: "SGK İşçi Payı", tutar: sgkIsci, oran: 14))
        kesintiler.append(KesintiKalemi(ad: "İşsizlik Sigortası İşçi Payı", tutar: issizlikIsci, oran: 1))
        
        // Adım 2: Bu ayki gelir vergisi matrahı
        let aylikMatrah = (brut - sgkIsci - issizlikIsci).yuvarla()
        
        // Adım 3-4: Kümülatif matrah ve vergi (önceki aylar + bu ay)
        let oncekiAylarMatrahlari = oncekiAylarBrutlari.map { ob -> Double in
            let base = min(ob, sgkTavani)
            let sgk = (base * sgkIsciOrani).yuvarla()
            let iss = (base * issizlikIsciOrani).yuvarla()
            return (ob - sgk - iss).yuvarla()
        }
        let kumulatifMatrahOnceki = oncekiAylarMatrahlari.reduce(0, +)
        let kumulatifMatrahBuAy = kumulatifMatrahOnceki + aylikMatrah
        
        // Brüt gelir vergisi (bu ay için): Bu ay sonu kümülatif vergi - Geçen ay sonu kümülatif vergi
        let kumulatifVergiOnceki = kumulatifVergiHesapla(matrah: kumulatifMatrahOnceki)
        let kumulatifVergiBuAy = kumulatifVergiHesapla(matrah: kumulatifMatrahBuAy)
        let brutGelirVergisi = (kumulatifVergiBuAy - kumulatifVergiOnceki).yuvarla()
        
        // Adım 4: Asgari ücret vergi istisnası
        let oncekiAySayisi = oncekiAylarBrutlari.count
        let kumulatifAsgariMatrahOnceki = Double(oncekiAySayisi) * asgariUcretMatrah
        let kumulatifAsgariMatrahBuAy = Double(oncekiAySayisi + 1) * asgariUcretMatrah
        let asgariVergiOnceki = kumulatifVergiHesapla(matrah: kumulatifAsgariMatrahOnceki)
        let asgariVergiBuAy = kumulatifVergiHesapla(matrah: kumulatifAsgariMatrahBuAy)
        let asgariIstisnaBuAy = (asgariVergiBuAy - asgariVergiOnceki).yuvarla()
        
        // Net gelir vergisi (istisna düşülmüş)
        let netGelirVergisi = max(0, (brutGelirVergisi - asgariIstisnaBuAy).yuvarla())
        kesintiler.append(KesintiKalemi(ad: "Gelir Vergisi", tutar: netGelirVergisi, oran: nil))
        
        // Adım 5: Damga vergisi (asgari ücret üzeri kısımdan)
        let damgaMatrah = max(0, brut - asgariUcretBrut)
        let damgaVergisi = (damgaMatrah * damgaVergisiOrani).yuvarla()
        kesintiler.append(KesintiKalemi(ad: "Damga Vergisi", tutar: damgaVergisi, oran: 0.759))
        
        // Adım 6: Net maaş
        let toplamKesinti = kesintiler.reduce(0) { $0 + $1.tutar }
        let net = (brut - toplamKesinti).yuvarla()
        
        return Sonuc(brut: brut, net: net, kesintiler: kesintiler, toplamKesinti: toplamKesinti)
    }
    
    /// Kümülatif matraha göre toplam vergi (yıllık dilimler)
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
    
    /// Yıllık tüm aylar için hesaplama (döngü ile, kümülatif matrah doğru akar)
    static func hesaplaYillik(brutlar: [Double]) -> [Sonuc] {
        var sonuclar: [Sonuc] = []
        var oncekiAylarBrut: [Double] = []
        
        for (index, brut) in brutlar.enumerated() {
            let ay = index + 1
            let sonuc = hesapla(brut: brut, ay: ay, oncekiAylarBrutlari: oncekiAylarBrut)
            sonuclar.append(sonuc)
            oncekiAylarBrut.append(brut)
        }
        
        return sonuclar
    }
    
    /// Yıllık detaylı hesaplama (tablo gösterimi için tüm sütunlar)
    static func hesaplaYillikDetayli(brutlar: [Double]) -> [AylikBrutNetDetay] {
        var detaylar: [AylikBrutNetDetay] = []
        var oncekiAylarBrut: [Double] = []
        
        for (index, brut) in brutlar.enumerated() {
            guard brut > 0 else {
                detaylar.append(AylikBrutNetDetay(ay: index + 1, brut: 0, sgkIsci: 0, issizlikIsci: 0, aylikGelirVergisi: 0, damgaVergisi: 0, kumulatifVergiMatrahi: 0, netVergiOncesi: 0, agi: 0, asgariUcretGVIstisnasi: 0, asgariUcretDVIstisnasi: 0, toplamNetEleGecen: 0, sgkIsveren: 0, issizlikIsveren: 0, toplamMaliyet: 0))
                oncekiAylarBrut.append(0)
                continue
            }
            
            let sgkBase = min(brut, sgkTavani)
            let sgkIsci = (sgkBase * sgkIsciOrani).yuvarla()
            let issizlikIsci = (sgkBase * issizlikIsciOrani).yuvarla()
            let aylikMatrah = (brut - sgkIsci - issizlikIsci).yuvarla()
            
            let oncekiAylarMatrahlari = oncekiAylarBrutlariMatrahlari(oncekiAylarBrut)
            let kumulatifMatrahOnceki = oncekiAylarMatrahlari.reduce(0, +)
            let kumulatifMatrahBuAy = kumulatifMatrahOnceki + aylikMatrah
            
            let kumulatifVergiOnceki = kumulatifVergiHesapla(matrah: kumulatifMatrahOnceki)
            let kumulatifVergiBuAy = kumulatifVergiHesapla(matrah: kumulatifMatrahBuAy)
            let brutGelirVergisi = (kumulatifVergiBuAy - kumulatifVergiOnceki).yuvarla()
            
            let oncekiAySayisi = oncekiAylarBrut.count
            let kumulatifAsgariMatrahOnceki = Double(oncekiAySayisi) * asgariUcretMatrah
            let kumulatifAsgariMatrahBuAy = Double(oncekiAySayisi + 1) * asgariUcretMatrah
            let asgariVergiOnceki = kumulatifVergiHesapla(matrah: kumulatifAsgariMatrahOnceki)
            let asgariVergiBuAy = kumulatifVergiHesapla(matrah: kumulatifAsgariMatrahBuAy)
            let asgariGVIstisnasi = (asgariVergiBuAy - asgariVergiOnceki).yuvarla()
            let netGelirVergisi = max(0, (brutGelirVergisi - asgariGVIstisnasi).yuvarla())
            
            let damgaMatrah = max(0, brut - asgariUcretBrut)
            let damgaVergisi = (damgaMatrah * damgaVergisiOrani).yuvarla()
            let asgariDVIstisnasi = (asgariUcretBrut * damgaVergisiOrani).yuvarla()
            
            let netVergiOncesi = (brut - sgkIsci - issizlikIsci - brutGelirVergisi - damgaVergisi).yuvarla()
            // Toplam Net = Net vergi öncesi + Asgari GV İstisnası (+ AGİ=0). Asgari DV istisnası sadece bilgi amaçlıdır.
            let toplamNetEleGecen = (netVergiOncesi + asgariGVIstisnasi).yuvarla()
            
            let sgkIsveren = (sgkBase * sgkIsverenOrani).yuvarla()
            let issizlikIsveren = (sgkBase * issizlikIsverenOrani).yuvarla()
            let toplamMaliyet = (brut + sgkIsveren + issizlikIsveren).yuvarla()
            
            detaylar.append(AylikBrutNetDetay(
                ay: index + 1,
                brut: brut,
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
            oncekiAylarBrut.append(brut)
        }
        
        return detaylar
    }
    
    private static func oncekiAylarBrutlariMatrahlari(_ brutlar: [Double]) -> [Double] {
        brutlar.map { ob -> Double in
            guard ob > 0 else { return 0 }
            let base = min(ob, sgkTavani)
            let sgk = (base * sgkIsciOrani).yuvarla()
            let iss = (base * issizlikIsciOrani).yuvarla()
            return (ob - sgk - iss).yuvarla()
        }
    }
}

private extension Double {
    func yuvarla() -> Double {
        (self * 100).rounded() / 100
    }
}
